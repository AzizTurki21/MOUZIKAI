import os
import sys
import queue
from pathlib import Path

# --------------------------------------------------
# PySide6 DLL setup — must run before importing Qt
# --------------------------------------------------
import PySide6

_PYSIDE_DIR = Path(PySide6.__file__).resolve().parent
_DLL_HANDLES = []

for _dll_dir in (
    _PYSIDE_DIR,
    _PYSIDE_DIR / "Qt" / "bin",
    _PYSIDE_DIR / "plugins",
    _PYSIDE_DIR / "qml" / "QtQuick",
    _PYSIDE_DIR / "qml" / "QtQuick" / "Controls",
    _PYSIDE_DIR / "qml" / "QtQuick3D",
):
    if _dll_dir.is_dir():
        _DLL_HANDLES.append(os.add_dll_directory(str(_dll_dir)))

# --------------------------------------------------
# Other imports
# --------------------------------------------------
import cv2
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, Qt
from PySide6.QtGui import QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider
from PySide6.QtWidgets import QApplication

from src.config import APP_TITLE, MODEL_PATH, MUSIC_DIR
from src.music_player import MusicPlayer
from src.vision import VisionWorker


class CameraProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Image)
        self._image = QImage(960, 540, QImage.Format_RGB888)
        self._image.fill(0x08091b)

    def set_frame(self, frame):
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        h, w, channels = rgb.shape
        image = QImage(
            rgb.data,
            w,
            h,
            channels * w,
            QImage.Format_RGB888,
        ).copy()
        self._image = image

    def requestImage(self, image_id, size, requested_size):
        image = self._image

        if requested_size.width() > 0 and requested_size.height() > 0:
            image = image.scaled(
                requested_size,
                Qt.IgnoreAspectRatio,
                Qt.SmoothTransformation,
            )

        if size is not None:
            size.setWidth(image.width())
            size.setHeight(image.height())

        return image


class MusicBridge(QObject):
    tracksChanged = Signal()
    currentTrackChanged = Signal()
    playbackChanged = Signal()
    volumeChanged = Signal()
    cameraChanged = Signal()
    gestureChanged = Signal()
    frameChanged = Signal()
    errorRaised = Signal(str)

    def __init__(self, provider):
        super().__init__()

        self.player = MusicPlayer(MUSIC_DIR)
        self.provider = provider
        self.worker = None

        self.frames = queue.Queue(maxsize=1)
        self.events = queue.Queue()

        self._camera_running = False
        self._gesture = "Waiting for a gesture"
        self._frame_revision = 0
        self._tracks = [p.stem for p in self.player.tracks]
        self._selected = 0

        if self.player.tracks:
            self.player.select(0)

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._poll)
        self._timer.start(30)

    @Property("QVariantList", notify=tracksChanged)
    def tracks(self):
        return self._tracks

    @Property(str, notify=currentTrackChanged)
    def currentTrack(self):
        track = self.player.current_track
        return track.stem if track else "No track selected"

    @Property(float, notify=volumeChanged)
    def volume(self):
        return float(self.player.volume)

    @Property(bool, notify=playbackChanged)
    def playing(self):
        return bool(self.player.is_playing)

    @Property(bool, notify=cameraChanged)
    def cameraRunning(self):
        return self._camera_running

    @Property(str, notify=gestureChanged)
    def gesture(self):
        return self._gesture

    @Property(int, notify=frameChanged)
    def frameRevision(self):
        return self._frame_revision

    @Slot(int)
    def selectTrack(self, index):
        if 0 <= index < len(self.player.tracks):
            self._selected = index
            self.player.select(index)
            self.currentTrackChanged.emit()

    @Slot()
    def play(self):
        if self.player.current_track is None and self.player.tracks:
            self.player.select(self._selected)
        self.player.play()
        self.playbackChanged.emit()
        self.currentTrackChanged.emit()

    @Slot()
    def pause(self):
        self.player.pause()
        self.playbackChanged.emit()

    @Slot()
    def togglePlayback(self):
        if self.player.is_playing:
            self.pause()
        else:
            self.play()

    @Slot()
    def stop(self):
        self.player.stop()
        self.playbackChanged.emit()

    @Slot()
    def nextTrack(self):
        if self.player.tracks:
            self.player.next()
            self._selected = self.player.tracks.index(self.player.current_track)
            self.currentTrackChanged.emit()
            self.playbackChanged.emit()

    @Slot()
    def previousTrack(self):
        if not self.player.tracks:
            return

        current = (
            self.player.tracks.index(self.player.current_track)
            if self.player.current_track in self.player.tracks
            else 0
        )
        self._selected = (current - 1) % len(self.player.tracks)
        self.player.select(self._selected)
        self.player.play()
        self.currentTrackChanged.emit()
        self.playbackChanged.emit()

    @Slot(float)
    def setVolume(self, value):
        self.player.set_volume(max(0.0, min(1.0, float(value))))
        self.volumeChanged.emit()

    @Slot()
    def toggleCamera(self):
        if self._camera_running:
            self.stopCamera()
        else:
            self.startCamera()

    @Slot()
    def startCamera(self):
        if not MODEL_PATH.exists():
            self.errorRaised.emit(
                f"Hand model not found. Put hand_landmarker.task in: {MODEL_PATH.parent}"
            )
            return

        try:
            self.worker = VisionWorker(MODEL_PATH, self.frames, self.events)
            self.worker.start()
            self._camera_running = True
            self.cameraChanged.emit()
        except Exception as exc:
            self.errorRaised.emit(f"Could not start camera: {exc}")

    @Slot()
    def stopCamera(self):
        if self.worker:
            self.worker.stop()
            self.worker = None

        self._camera_running = False
        self.cameraChanged.emit()
        self._gesture = "Camera stopped"
        self.gestureChanged.emit()

    def _gesture_action(self, gesture):
        if gesture == "INDEX":
            self.player.play()
            self.playbackChanged.emit()
        elif gesture == "FIST":
            self.player.pause()
            self.playbackChanged.emit()
        elif gesture == "PEACE":
            self.player.set_volume(self.player.volume + 0.08)
            self.volumeChanged.emit()
        elif gesture == "THUMB UP":
            self.player.set_volume(self.player.volume - 0.08)
            self.volumeChanged.emit()
        elif gesture == "OPEN PALM":
            self.nextTrack()

    def _poll(self):
        try:
            while True:
                frame = self.frames.get_nowait()
                self.provider.set_frame(frame)
                self._frame_revision += 1
                self.frameChanged.emit()
        except queue.Empty:
            pass

        try:
            while True:
                gesture, score = self.events.get_nowait()
                if gesture in ("CAMERA ERROR", "VISION ERROR"):
                    self.errorRaised.emit(gesture)
                    self._gesture = gesture
                else:
                    self._gesture = gesture
                    self._gesture_action(gesture)
                self.gestureChanged.emit()
        except queue.Empty:
            pass

    @Slot()
    def shutdown(self):
        self.stopCamera()
        self.player.close()


def main():
    app = QApplication(sys.argv)
    app.setApplicationName(APP_TITLE)

    provider = CameraProvider()
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(_PYSIDE_DIR / "qml"))
    bridge = MusicBridge(provider)

    engine.addImportPath(str(_PYSIDE_DIR / "qml"))
    engine.addImageProvider("camera", provider)
    engine.rootContext().setContextProperty("music", bridge)

    qml_file = Path(__file__).parent / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        bridge.shutdown()
        return 1

    app.aboutToQuit.connect(bridge.shutdown)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
