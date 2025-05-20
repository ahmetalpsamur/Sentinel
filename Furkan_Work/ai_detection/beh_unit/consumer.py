import os
import json
from kafka import KafkaConsumer
from logger import setup_logger
from video_processor import classify_video
from db_handler import save_top_prediction

logger = setup_logger("beh_log")

KAFKA_SERVER = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
TOPIC_NAME = "segment_videos"

logger.info(f"🔄 Connecting to Kafka broker: {KAFKA_SERVER}")
consumer = KafkaConsumer(
    TOPIC_NAME,
    bootstrap_servers=[KAFKA_SERVER],
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id="crime_detection_group"
)
logger.info(f"✅ Connected. Listening on topic: {TOPIC_NAME}")

for message in consumer:
    logger.info(f"📥 Message received: {message.value}")
    data = message.value
    video_id = data.get("segment_id") or data.get("id")
    video_path = data.get("path")

    if not video_id:
        logger.warning(f"❗ Missing 'video_id' in message: {data}")
        continue

    if not video_path:
        logger.warning(f"❗ Missing 'path' in message: {data}")
        continue

    if not os.path.exists(video_path):
        logger.warning(f"❗ File not found at path: {video_path}")
        continue


    logger.info(f"📂 Found file. Beginning classification for video_id={video_id}")
    predictions = classify_video(video_path)

    if predictions:
        logger.info(f"✅ Classification success for {video_id}. Saving top prediction.")
        for label, score in predictions.items():
            logger.info(f"   {label}: {score:.2f}%")
        save_top_prediction(video_id, predictions)
    else:
        logger.error(f"❌ Classification failed for: {video_path}")



