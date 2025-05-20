import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import cv2
import base64
import uuid
import json
from kafka_config import create_consumer,create_producer
from redis_config import get_redis_client
from filter_pipeline import preprocess_frame
from logger import setup_logger
from db_manager import insert_video_metadata
from time import sleep
from concurrent.futures import ThreadPoolExecutor

executor = ThreadPoolExecutor(max_workers=4)

logger = setup_logger()

consumer = create_consumer("video_uploaded")


def save_to_redis(frame_id,frame_index, data, redis_client):
    if not redis_client:
        logger.warning("🚫 Redis istemcisi mevcut değil. Frame saklanamadı.")
        return
    try:

        redis_client.setex(f"frame:{frame_id}", 300, json.dumps(data))


        redis_client.setex(f"frame_index:{frame_index}", 300, frame_id)
        logger.debug(f"✅ Redis'e kaydedildi: frame:{frame_id}")
    except Exception as e:
        logger.error(f"❌ Redis'e yazarken hata: {e}")


def send_to_kafka(data, producer):
    try:
        producer.send("to_ai_unit", data)
        producer.flush()
        logger.info(f"Kafka'ya mesaj gönderildi. Video ID: {data['src_video_id']}, Frame ID: {data['frame_id']}")
    except Exception as e:
        logger.error(f"Kafka gönderimi başarısız: {e}")

def encode_frame_to_base64(frame):
    _, buffer = cv2.imencode('.jpg', frame)
    return base64.b64encode(buffer).decode('utf-8')

def process_video(video_path):
    logger.info(f"🎬 Videoyu işleme başlatılıyor: {video_path}")
    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        logger.error(f"❌ Video açılamadı: {video_path}")
        return

    # Video meta bilgilerini al
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    # video_id'yi video_path'ten türet
    video_id = os.path.basename(video_path).split("_")[0]
    # Metadata'yı veritabanına yaz
    insert_video_metadata(video_id, video_path, fps, width, height, total_frames)

    redis_client=get_redis_client()
    producer = create_producer()

    index = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            logger.info("📭 Video sonu geldi veya frame okunamadı.")
            break

        frame_id = str(uuid.uuid4())
        if index % 30 == 0:
            logger.info(f"🔄 Frame {index} alındı, işleniyor. Frame ID: {frame_id}")

        try:
            original_encoded = encode_frame_to_base64(frame)
            filtered_frame = preprocess_frame(frame)
            filtered_encoded = encode_frame_to_base64(filtered_frame)
        except Exception as e:
            logger.error(f"❌ Frame {index} işlenirken hata: {e}")
            continue

        redis_data = {
            "frame_id": frame_id,
            "frame_index": index,
            "src_video_id": video_id,
            "original_data": original_encoded,  
            "filtered_data": filtered_encoded
        }

        ai_data = {
            "frame_id": frame_id,
            "frame_index": index,
            "src_video_id": video_id
        }
        executor.submit(save_to_redis, frame_id,index, redis_data,redis_client)
        executor.submit(send_to_kafka, ai_data,producer)
        index += 1

    cap.release()
    logger.info(f"🏁 Video işleme tamamlandı: {video_path}")

    try:
        os.remove(video_path)
        logger.info(f"🗑️ Video dosyası silindi: {video_path}")
    except Exception as e:
        logger.warning(f"⚠️ Video silinemedi: {e}")

# Kafka'dan veri geldiğinde çalışacak
for msg in consumer:
    video_path = msg.value.get("path")
    logger.info(f"📩 Kafka'dan mesaj alındı. Video yolu: {video_path}")

    if not os.path.exists(video_path):
        logger.error(f"❌ Dosya mevcut değil: {video_path}")
        continue

    process_video(video_path)
