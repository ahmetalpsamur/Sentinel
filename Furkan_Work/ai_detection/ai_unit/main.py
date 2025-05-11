import json
import torch
import logging
from kafka_manager import KafkaManager
from image_processor import ImageProcessor
from utils.redis_config import get_redis_client
from utils.logger import setup_logger
from config import Config
from TRTModelService import TRTModelService


def main():
    # Logger kurulumu
    logger = setup_logger()
    
    try:
        # Bağımlılıkların kurulumu
        kafka_manager = KafkaManager()
        
        image_processor = ImageProcessor()
        #model_service = ModelService()
        model_service = TRTModelService("models/model.engine")
        redis_client = get_redis_client()
        
        # Kafka bağlantıları
        consumer = kafka_manager.get_consumer()
        producer = kafka_manager.get_producer()
        
        logger.info("🚀 AI Unit service started successfully")
        
        # Ana işlem döngüsü
        for msg in consumer:
            try:
                process_message(msg, image_processor, model_service, redis_client, producer)
            except Exception as e:
                logger.error(f"Message processing failed: {e}")
                #if model_service.device.type == 'cuda':
                #    torch.cuda.empty_cache()

    
    except KeyboardInterrupt:
        logger.info("🛑 Service stopped by user")
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}")
    finally:
        if 'consumer' in locals():
            consumer.close()
        if 'producer' in locals():
            producer.close()
        logger.info("🔌 Resources released")

def process_message(msg, image_processor, model_service, redis_client, producer):
    """Tek bir mesajı işler"""
    logger = setup_logger()
    
    if not msg.value:
        logger.warning("Empty message received")
        return

    frame_id = msg.value.get("frame_id")
    frame_index = msg.value.get("frame_index")
    src_video_id = msg.value.get("src_video_id")
    
    if not all([frame_id, frame_index, src_video_id]):
        logger.error("Invalid message format")
        return

    logger.info(f"Processing frame: {frame_id}")
    
    # Redis'ten veri çek
    redis_key = f"frame:{frame_id}"
    redis_data = redis_client.get(redis_key)
    if not redis_data:
        logger.warning(f"Frame not found in Redis: {redis_key}")
        return

    # Görüntüyü işle
    frame_data = json.loads(redis_data)
    frame = image_processor.decode_image(frame_data["filtered_data"])
    if frame is None:
        return

    # Tahmin yap
    predictions = model_service.predict(frame)
    
    if predictions['boxes']:
        # Sonuçları hazırla
        result = {
            "frame_id": frame_id,
            "frame_index": frame_index,
            "src_video_id": src_video_id,
            "confidence": float(max(predictions['confs'])) if predictions['confs'] else 0.0,
            "is_detected": True,
            "bounding_boxes": predictions['boxes']
        }
        
        # Kafka'ya gönder
        producer.send(Config.OUTPUT_TOPIC, result)
        producer.flush()
        
        # Görüntüyü kaydet
        #annotated_image = image_processor.draw_boxes(frame.copy(), predictions['boxes'])
        #image_processor.save_image(annotated_image, frame_id)
        
        logger.info(f"Processed frame {frame_id} with {len(predictions['boxes'])} detections, frame index:{frame_index} , confident: {max(predictions['confs'])}")
    else:
        logger.debug(f"No detections in frame {frame_id} and frame index:{frame_index}")

if __name__ == "__main__":
    main()