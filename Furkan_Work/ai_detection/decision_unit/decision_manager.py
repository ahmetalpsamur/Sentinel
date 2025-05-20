import time
from threading import Lock
from config import Config
from utils.video_utils import get_video_metadata

class FrameBuffer:
    def __init__(self, timeout_seconds=Config.BASE_TIMEOUT_SECONDS):
        self.buffers = {}  # video_id: { "frames": [...], "last_update": timestamp }
        self.lock = Lock()
        self.timeout_seconds = timeout_seconds


    def add_frame(self, src_video_id, frame_index, frame_id, is_detected, detections=None):
        with self.lock:
            if src_video_id not in self.buffers:
                self.buffers[src_video_id] = {
                    "frames": [],
                    "last_update": time.time()
                }

            self.buffers[src_video_id]["frames"].append({
                "frame_id": frame_id,
                "frame_index": frame_index,
                "is_detected": is_detected,
                "detections": detections or []
            })
            self.buffers[src_video_id]["last_update"] = time.time()

    def calculate_dynamic_timeout(self, video_id):
        """Videonun FPS'ine göre timeout hesapla"""
        metadata = get_video_metadata(video_id)
        if not metadata:
            return self.timeout_seconds
        
        fps = metadata['fps']
        # Örnek formül: timeout = base + (FPS * per_unit)
        return Config.BASE_TIMEOUT_SECONDS + (fps * Config.TIMEOUT_PER_FPS)


    def get_completed_videos(self):
        with self.lock:
            completed = []
            for video_id, data in self.buffers.items():
                # Dinamik timeout hesapla
                dynamic_timeout = self.calculate_dynamic_timeout(video_id)
                if time.time() - data["last_update"] > dynamic_timeout:
                    completed.append(video_id)
            return completed

    def pop_video_frames(self, video_id):
        with self.lock:
            data = self.buffers.pop(video_id, None)
            return data["frames"] if data else []
