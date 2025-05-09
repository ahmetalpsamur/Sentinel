import os
import json
import base64
import numpy as np
import cv2
from kafka import KafkaConsumer, KafkaProducer
from ultralytics import YOLO
from redis_config import get_redis_client
from logger import setup_logger

# Logger setup
logger = setup_logger("ai_unit", "logs/ai_unit.log")

# Kafka ayarları
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
INPUT_TOPIC = "to_ai_unit"
OUTPUT_TOPIC = "ai_results"

# Kafka consumer
consumer = KafkaConsumer(
    INPUT_TOPIC,
    bootstrap_servers=KAFKA_BOOTSTRAP,
    value_deserializer=lambda x: json.loads(x.decode('utf-8')),
    group_id='ai-unit-group',
    auto_offset_reset='earliest'
)

# Kafka producer
producer = KafkaProducer(
    bootstrap_servers=KAFKA_BOOTSTRAP,
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)

# Redis bağlantısı
redis_client = get_redis_client()

# Model yükleniyor
base_dir = os.path.dirname(__file__)
model_path = os.path.join(base_dir, "models", "reSizedV1.pt")

model = YOLO(model_path)

def decode_base64_image(b64_string):
    try:
        img_data = base64.b64decode(b64_string)
        np_arr = np.frombuffer(img_data, np.uint8)
        return cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    except Exception as e:
        logger.error(f"❌ Base64 çözümleme hatası: {e}")
        return None


def draw_boxes_and_save(image, boxes, save_path):
    for box in boxes:
        x1, y1, x2, y2 = map(int, box)
        cv2.rectangle(image, (x1, y1), (x2, y2), color=(0, 255, 0), thickness=2)
    
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    cv2.imwrite(save_path, image)


for msg in consumer:
    frame_id = msg.value.get("frame_id")
    frame_index = msg.value.get("frame_index")
    src_video_id = msg.value.get("src_video_id")

    logger.info(f"📥 Kafka'dan frame alındı: {frame_id}")

    try:
        redis_key = f"frame:{frame_id}"
        redis_data = redis_client.get(redis_key)
        if not redis_data:
            logger.warning(f"🚫 Redis'te veri bulunamadı: {redis_key}")
            continue

        frame_data = json.loads(redis_data)
        frame_image = decode_base64_image(frame_data["filtered_data"])
        if frame_image is None:
            continue

        # YOLO tahmini
        results = model(frame_image)[0]  # YOLOv8 output
        boxes = results.boxes
        confs = boxes.conf.cpu().tolist() if boxes.conf is not None else []
        xyxy = boxes.xyxy.cpu().tolist() if boxes.xyxy is not None else []

        is_detected = len(xyxy) > 0

        if is_detected:
            output = {
                "frame_id": frame_id,
                "frame_index": frame_index,
                "src_video_id": src_video_id,
                "confidence": max(confs) if confs else 0,
                "is_detected": True,
                "bounding_boxes": xyxy  # her biri [x1, y1, x2, y2]
            }
            producer.send(OUTPUT_TOPIC, output)
            producer.flush()
            logger.info(f"✅ Tespit sonucu gönderildi. Frame ID: {frame_id}")
            
            # Save image with boxes
            image_save_path = os.path.join("frame", f"{frame_id}.jpg")
            draw_boxes_and_save(frame_image, xyxy, image_save_path)
            logger.info(f"💾 Tespit edilen frame kaydedildi: {image_save_path}")
        else:
            logger.debug(f"⛔ Herhangi bir nesne tespit edilmedi: {frame_id}")

    except Exception as e:
        logger.error(f"❌ Frame işlenirken hata oluştu: {e}")
