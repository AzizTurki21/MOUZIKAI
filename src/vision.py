import queue
import threading
import time
from pathlib import Path

import cv2
import mediapipe as mp

from .config import (
    CAMERA_INDEX,
    CAMERA_WIDTH,
    CAMERA_HEIGHT,
    MAX_HANDS,
    DETECTION_CONFIDENCE,
    PRESENCE_CONFIDENCE,
    TRACKING_CONFIDENCE,
    GESTURE_STABLE_FRAMES,
    GESTURE_COOLDOWN_SECONDS,
)
from .gestures import classify_gesture


HAND_CONNECTIONS = (
    (0, 1), (1, 2), (2, 3), (3, 4),
    (0, 5), (5, 6), (6, 7), (7, 8),
    (5, 9), (9, 10), (10, 11), (11, 12),
    (9, 13), (13, 14), (14, 15), (15, 16),
    (13, 17), (17, 18), (18, 19), (19, 20),
    (0, 17),
)


class VisionWorker:
    def __init__(self, model_path: Path, frame_queue: queue.Queue, event_queue: queue.Queue):
        self.model_path = Path(model_path)
        self.frame_queue = frame_queue
        self.event_queue = event_queue
        self.stop_event = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True, name="GestureStageVision")
        self.error = None

    def start(self):
        self.thread.start()

    def stop(self):
        self.stop_event.set()
        if self.thread.is_alive():
            self.thread.join(timeout=2.5)

    @staticmethod
    def _send_latest(target, value):
        try:
            target.put_nowait(value)
        except queue.Full:
            try:
                target.get_nowait()
            except queue.Empty:
                pass
            try:
                target.put_nowait(value)
            except queue.Full:
                pass

    def _run(self):
        camera = cv2.VideoCapture(CAMERA_INDEX, cv2.CAP_DSHOW)
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

        if not camera.isOpened():
            self.error = "The webcam could not be opened."
            self._send_latest(self.event_queue, ("CAMERA ERROR", 0.0))
            return

        BaseOptions = mp.tasks.BaseOptions
        HandLandmarker = mp.tasks.vision.HandLandmarker
        HandLandmarkerOptions = mp.tasks.vision.HandLandmarkerOptions
        RunningMode = mp.tasks.vision.RunningMode

        options = HandLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=str(self.model_path)),
            running_mode=RunningMode.VIDEO,
            num_hands=MAX_HANDS,
            min_hand_detection_confidence=DETECTION_CONFIDENCE,
            min_hand_presence_confidence=PRESENCE_CONFIDENCE,
            min_tracking_confidence=TRACKING_CONFIDENCE,
        )

        current_gesture = "UNKNOWN"
        stable_frames = 0
        last_emitted = None
        last_event_time = 0.0
        last_timestamp = 0

        try:
            with HandLandmarker.create_from_options(options) as landmarker:
                while not self.stop_event.is_set():
                    success, frame = camera.read()
                    if not success:
                        self.error = "A frame could not be read from the webcam."
                        break

                    frame = cv2.flip(frame, 1)
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

                    timestamp = max(time.monotonic_ns() // 1_000_000, last_timestamp + 1)
                    last_timestamp = timestamp
                    result = landmarker.detect_for_video(mp_image, timestamp)

                    gesture = "NO HAND"
                    if result.hand_landmarks:
                        landmarks = result.hand_landmarks[0]
                        gesture = classify_gesture(landmarks)
                        height, width, _ = frame.shape
                        points = [
                            (int(point.x * width), int(point.y * height))
                            for point in landmarks
                        ]

                        for start, end in HAND_CONNECTIONS:
                            cv2.line(frame, points[start], points[end], (86, 222, 191), 2)
                        for point in points:
                            cv2.circle(frame, point, 4, (245, 250, 255), -1)

                    if gesture == current_gesture:
                        stable_frames += 1
                    else:
                        current_gesture = gesture
                        stable_frames = 1
                        last_emitted = None

                    now = time.monotonic()
                    if (
                        gesture not in ("UNKNOWN", "NO HAND")
                        and stable_frames >= GESTURE_STABLE_FRAMES
                        and gesture != last_emitted
                        and now - last_event_time >= GESTURE_COOLDOWN_SECONDS
                    ):
                        self._send_latest(self.event_queue, (gesture, 1.0))
                        last_emitted = gesture
                        last_event_time = now

                    cv2.putText(
                        frame,
                        f"GESTURE  {gesture}",
                        (22, 40),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.85,
                        (86, 222, 191),
                        2,
                        cv2.LINE_AA,
                    )
                    self._send_latest(self.frame_queue, frame)

        except Exception as exc:
            self.error = str(exc)
            self._send_latest(self.event_queue, ("VISION ERROR", 0.0))
        finally:
            camera.release()
