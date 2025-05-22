from fastapi import FastAPI, UploadFile, File, HTTPException
import os, json, uuid,time
from logger import setup_logger
from kafka import KafkaProducer
from fastapi.responses import FileResponse, JSONResponse
import aiosqlite
from fastapi.responses import HTMLResponse,StreamingResponse  
from fastapi import APIRouter
from pathlib import Path
from fastapi.middleware.cors import CORSMiddleware



app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
logger = setup_logger()

DATA_DIR = os.path.join(os.getcwd(), "data", "uploaded_videos")
os.makedirs(DATA_DIR, exist_ok=True)
KAFKA_SERVER = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
DB_PATH = os.getenv("DB_PATH", "./data/videos.db")
router = APIRouter()


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
    logger.info("Video alındı.")
    if not file.filename.lower().endswith((".mp4", ".mov", ".avi", ".mkv")):
        logger.warning(f"Geçersiz dosya türü: {file.filename}")
        raise HTTPException(status_code=400, detail="Only video files with common extensions are allowed.")

    file_id = str(uuid.uuid4())
    save_path = os.path.join(DATA_DIR, f"{file_id}_{file.filename}")


    try:
        content = await file.read()

        with open(save_path, "wb") as f:
            f.write(content)
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

@app.get("/segments/")
async def get_all_segments():
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute("""
                SELECT s.segment_id,s.url, s.description, s.weapon_score, s.crime_score, 
                       s.weapon_type, s.timestamp, s.crime_type 
                FROM segment s 
                WHERE s.reported=0
            """)
            rows = await cursor.fetchall()
            await cursor.close()

        segments = []
        for row in rows:
            segments.append({
                "id": row["segment_id"],
                "title": row["description"][:50],  
                "description": row["description"],
                "videoUrl": row["url"],
                "crimeProbability": row["crime_score"],
                "weaponProbability": row["weapon_score"],
                "weaponType": row["weapon_type"],
                "timestamp": row["timestamp"],
                "crimeType": row["crime_type"]
            })

        logger.info(f"{len(segments)} segment Flutter'a gönderildi.")
        return {"videos": segments}

    except Exception as e:
        logger.error(f"Segment verileri alınamadı: {e}")
        raise HTTPException(status_code=500, detail="Database error.")
    
@app.get("/reported_segments/")
async def get_all_reported_segments():
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute("""
                SELECT s.segment_id,s.url, s.description, s.weapon_score, s.crime_score, 
                       s.weapon_type, s.timestamp, s.crime_type 
                FROM segment s 
                WHERE s.reported=1
            """)
            rows = await cursor.fetchall()
            await cursor.close()

        segments = []
        for row in rows:
            segments.append({
                "id": row["segment_id"],
                "title": row["description"][:50],  
                "description": row["description"],
                "videoUrl": row["url"],
                "crimeProbability": row["crime_score"],
                "weaponProbability": row["weapon_score"],
                "weaponType": row["weapon_type"],
                "timestamp": row["timestamp"],
                "crimeType": row["crime_type"]
            })

        logger.info(f"{len(segments)} segment Flutter'a gönderildi.")
        return {"videos": segments}

    except Exception as e:
        logger.error(f"Segment verileri alınamadı: {e}")
        raise HTTPException(status_code=500, detail="Database error.")

@app.post("/segments/report/{segment_id}")
async def report_segment(segment_id: str):
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            cursor = await db.execute(
                "SELECT segment_id FROM segment WHERE segment_id = ?", (segment_id,)
            )
            row = await cursor.fetchone()
            await cursor.close()

            if row is None:
                logger.warning(f"Segment bulunamadı: {segment_id}")
                raise HTTPException(status_code=404, detail="Segment not found")

            await db.execute(
                "UPDATE segment SET reported = 1 WHERE segment_id = ?", (segment_id,)
            )
            await db.commit()

        logger.info(f"Segment reported olarak işaretlendi: {segment_id}")
        return {"message": f"Segment {segment_id} successfully marked as reported."}

    except Exception as e:
        logger.error(f"Segment report işlemi başarısız: {e}")
        raise HTTPException(status_code=500, detail="Internal server error.")

@app.get("/watch/{segment_id}", response_class=HTMLResponse)
async def watch_segment(segment_id: str):
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            # Segment açıklama ve skor bilgilerini al
            meta_cursor = await db.execute(
                """SELECT description, weapon_score, crime_score 
                   FROM segment WHERE segment_id = ?""",
                (segment_id,)
            )
            meta_data = await meta_cursor.fetchone()

            # Video dosya yolunu al
            video_cursor = await db.execute(
                """SELECT output_path FROM segments 
                   WHERE segment_id = ?""",
                (segment_id,)
            )
            video_path_row = await video_cursor.fetchone()

            if not meta_data or not video_path_row:
                raise HTTPException(status_code=404, detail="Segment bulunamadı")

            output_path = video_path_row[0]
            full_video_path = Path(output_path)

            if not full_video_path.exists():
                raise HTTPException(status_code=404, detail="Video dosyası bulunamadı")

            description = meta_data[0]
            weapon_score = meta_data[1]
            crime_score = meta_data[2]

    except Exception as e:
        logger.error(f"Hata: {str(e)}")
        raise HTTPException(status_code=500, detail="İç sunucu hatası")

    # Dinamik HTML içerik
    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <title>Video Player</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{
                margin: 0;
                font-family: Arial, sans-serif;
                background-color: #f2f2f2;
                display: flex;
                flex-direction: column;
                align-items: center;
            }}

            .video-wrapper {{
                width: 70vw; /* Ekranın %70 genişliği */
                aspect-ratio: 16 / 9;
                background-color: #000;
                border-radius: 10px;
                overflow: hidden;
                margin-top: 30px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            }}

            video {{
                width: 100%;
                height: 100%;
            }}

            .meta-info {{
                width: 70vw;
                margin-top: 20px;
                padding: 15px;
                background-color: #fff;
                border-radius: 10px;
                box-shadow: 0 0 8px rgba(0, 0, 0, 0.1);
            }}
            h2 {{
                margin-top: 0;
            }}
        </style>
    </head>

    <body>
        <div class="container">
            <div class="video-wrapper">
                <video controls autoplay>
                    <source src="/stream/{segment_id}" type="video/mp4">
                    Tarayıcınız video desteği sağlamıyor.
                </video>
            </div>
            <div class="meta-info">
                <h2>{description}</h2>
                <p><strong>Weapon Score:</strong> {weapon_score:.4f}</p>
                <p><strong>Crime Score:</strong> {crime_score:.2f}</p>
            </div>
        </div>
    </body>

    </html>
    """
    return HTMLResponse(content=html_content)

@app.get("/stream/{segment_id}")
async def stream_video(segment_id: str):
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            cursor = await db.execute(
                """SELECT output_path FROM segments 
                   WHERE segment_id = ?""",
                (segment_id,)
            )
            row = await cursor.fetchone()
            
            if not row:
                raise HTTPException(status_code=404, detail="Segment bulunamadı")
            
            output_path = row[0]
            full_video_path = output_path

            if not os.path.isfile(output_path):
                raise HTTPException(status_code=404, detail="Video dosyası bulunamadı")

            return FileResponse(
                full_video_path,
                media_type="video/mp4",
                headers={"Accept-Ranges": "bytes"}
            )

    except Exception as e:
        logger.error(f"Stream hatası: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))