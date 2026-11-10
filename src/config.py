from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
MODEL_PATH = ROOT_DIR / "models" / "hand_landmarker.task"
MUSIC_DIR = ROOT_DIR / "assets" / "music"

APP_TITLE = "GestureStage | Gesture Music Control"
CAMERA_INDEX = 0
CAMERA_WIDTH = 960
CAMERA_HEIGHT = 540
MAX_HANDS = 1

DETECTION_CONFIDENCE = 0.65
PRESENCE_CONFIDENCE = 0.65
TRACKING_CONFIDENCE = 0.65

GESTURE_STABLE_FRAMES = 8
GESTURE_COOLDOWN_SECONDS = 0.8
