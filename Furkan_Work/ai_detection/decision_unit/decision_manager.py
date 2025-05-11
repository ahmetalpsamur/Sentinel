import time
from threading import Lock

class FrameBuffer:
    def __init__(self, timeout_seconds=15):
        self.buffers = {}  # video_id: { "frames": [...], "last_update": timestamp }
        self.lock = Lock()
        self.timeout_seconds = timeout_seconds

    def add_frame(self, src_video_id, frame_index, confidence, is_detected, frame_id, bounding_boxes=None):
        with self.lock:
            if src_video_id not in self.buffers:
                self.buffers[src_video_id] = {
                    "frames": [],
                    "last_update": time.time()
                }

            self.buffers[src_video_id]["frames"].append({
                "frame_id": frame_id,
                "frame_index": frame_index,
                "confidence": confidence,
                "is_detected": is_detected,
                "bounding_boxes": bounding_boxes or []
            })
            self.buffers[src_video_id]["last_update"] = time.time()

    def get_completed_videos(self):
        with self.lock:
            now = time.time()
            completed = []

            for video_id, data in self.buffers.items():
                if now - data["last_update"] > self.timeout_seconds:
                    completed.append(video_id)

            return completed

    def pop_video_frames(self, video_id):
        with self.lock:
            data = self.buffers.pop(video_id, None)
            return data["frames"] if data else []
