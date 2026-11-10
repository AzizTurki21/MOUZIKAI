from pathlib import Path
import pygame

AUDIO_FORMATS = {".mp3", ".wav", ".ogg"}


class MusicPlayer:
    def __init__(self, music_dir):
        self.music_dir = Path(music_dir)
        self.music_dir.mkdir(parents=True, exist_ok=True)
        self.tracks = sorted(
            (path for path in self.music_dir.iterdir()
             if path.is_file() and path.suffix.lower() in AUDIO_FORMATS),
            key=lambda path: path.name.casefold(),
        )
        pygame.mixer.init()
        self.volume = 0.65
        self.index = 0 if self.tracks else None
        self.paused = False
        pygame.mixer.music.set_volume(self.volume)

    @property
    def current_track(self):
        if self.index is None or not self.tracks:
            return None
        return self.tracks[self.index]

    @property
    def is_playing(self):
        return pygame.mixer.music.get_busy() and not self.paused

    def select(self, index):
        if self.tracks:
            self.index = max(0, min(int(index), len(self.tracks) - 1))
            self.paused = False

    def play(self):
        if self.current_track is None:
            return
        if self.paused:
            pygame.mixer.music.unpause()
            self.paused = False
            return
        pygame.mixer.music.load(str(self.current_track))
        pygame.mixer.music.set_volume(self.volume)
        pygame.mixer.music.play()

    def pause(self):
        if pygame.mixer.music.get_busy() and not self.paused:
            pygame.mixer.music.pause()
            self.paused = True

    def stop(self):
        pygame.mixer.music.stop()
        self.paused = False

    def next(self):
        if self.tracks:
            self.index = (self.index + 1) % len(self.tracks)
            self.paused = False
            self.play()

    def set_volume(self, value):
        self.volume = max(0.0, min(1.0, float(value)))
        pygame.mixer.music.set_volume(self.volume)

    def close(self):
        try:
            pygame.mixer.music.stop()
            pygame.mixer.quit()
        except pygame.error:
            pass
