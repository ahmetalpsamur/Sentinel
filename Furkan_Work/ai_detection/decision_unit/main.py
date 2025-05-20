import json
import threading
import time
from kafka_manager import KafkaManager
from decision_manager import FrameBuffer
from segment_builder import build_segment_for_video
from utils.logger import setup_logger
from config import Config

logger = setup_logger()
frame_buffer = FrameBuffer(timeout_seconds=Config.BUFFER_TIMEOUT)

def kafka_consumer_loop():
    kafka_manager = KafkaManager()
    consumer = kafka_manager.get_consumer(topic=Config.INPUT_TOPIC)
    logger.info("🎯 Kafka consumer started on topic: ai_results")

    for message in consumer:
        try:
            data = json.loads(message.value)  

            frame_id = data.get("frame_id")
            src_video_id = data.get("src_video_id")
            frame_index = data.get("frame_index")
            is_detected = data.get("is_detected", False)
            detections=data.get("detections",[])

            if src_video_id is None or frame_index is None:
                logger.warning(f"Geçersiz veri: {data}")
                continue

            frame_buffer.add_frame(
                src_video_id=src_video_id,
                frame_index=frame_index,
                frame_id=frame_id,
                is_detected=is_detected,
                detections=detections
            )


            logger.debug(f"🧩 Frame {frame_index} added for video {src_video_id}")

        except Exception as e:
            logger.error(f"Kafka message error: {e}")


def buffer_watcher_loop():
    while True:
        try:
            completed_videos = frame_buffer.get_completed_videos()
            for video_id in completed_videos:
                logger.info(f"📦 Video buffer timed out: {video_id}")
                frames = frame_buffer.pop_video_frames(video_id)
                if frames:
                    build_segment_for_video(
                        video_id=video_id,
                        frames=frames,
                        window_size=Config.SEGMENT_WINDOW_SIZE,
                        min_detections=Config.SEGMENT_MIN_DETECTIONS
                    )
        except Exception as e:
            logger.error(f"Buffer watcher error: {e}")

        time.sleep(5)

if __name__ == "__main__":
    logger.info("🚀 Decision Unit started")

    consumer_thread = threading.Thread(target=kafka_consumer_loop, daemon=True)
    watcher_thread = threading.Thread(target=buffer_watcher_loop, daemon=True)

    consumer_thread.start()
    watcher_thread.start()

    consumer_thread.join()
    watcher_thread.join()
    