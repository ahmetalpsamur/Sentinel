from fastapi import FastAPI, UploadFile, File, HTTPException
import os, json, uuid,time
from logger import setup_logger
from kafka import KafkaProducer

app = FastAPI()
logger = setup_logger("backend", "logs/backend.log")

DATA_DIR = os.path.join(os.getcwd(), "data", "uploaded_videos")
os.makedirs(DATA_DIR, exist_ok=True)
KAFKA_SERVER = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")

producer = None  

@app.on_event("startup")
def init_kafka():
    global producer

    for attempt in range(10):
        try:
            producer = KafkaProducer(
                bootstrap_servers=KAFKA_SERVER,
                value_serializer=lambda v: json.dumps(v).encode('utf-8')
            )
            logger.info("✅ Kafka producer başarıyla başlatıldı.")
            return
        except Exception as e:
            logger.warning(f"❗ Kafka bağlantısı denemesi başarısız ({attempt+1}/10): {e}")
            time.sleep(2)  # 2 saniye bekle, tekrar dene

    logger.error("🚫 Kafka producer başlatılamadı, çıkılıyor.")
    raise RuntimeError("Kafka bağlantısı kurulamadı")

@app.post("/upload_video/")
async def upload_video(file: UploadFile = File(...)):
    if not file.filename.lower().endswith((".mp4", ".mov", ".avi", ".mkv")):
        logger.warning(f"Geçersiz dosya türü: {file.filename}")
        raise HTTPException(status_code=400, detail="Only video files with common extensions are allowed.")

    file_id = str(uuid.uuid4())
    save_path = os.path.join(DATA_DIR, f"{file_id}_{file.filename}")

    try:
        with open(save_path, "wb") as f:
            f.write(await file.read())
        logger.info(f"Video kaydedildi: {save_path}")
    except Exception as e:
        logger.error(f"Video dosyası kaydedilemedi: {e}")
        raise HTTPException(status_code=500, detail="File save failed.")

    message = {
        "video_id": file_id,
        "filename": file.filename,
        "path": save_path
    }

    if producer is None:
        logger.error("Kafka producer tanımlı değil. Mesaj gönderilemedi.")
        raise HTTPException(status_code=503, detail="Kafka not available")

    try:
        producer.send("video_uploaded", message)
        producer.flush()
        logger.info(f"Kafka'ya mesaj gönderildi. Video ID: {file_id}")
    except Exception as e:
        logger.error(f"Kafka gönderimi başarısız: {e}")
        raise HTTPException(status_code=500, detail=f"Kafka error: {e}")

    return {"message": "Video received and dispatched.", "video_id": file_id}
