import sqlite3
import os
from logger import setup_logger
from datetime import datetime

logger = setup_logger("beh_log")  # Aynı log dosyasını kullanalım

DB_PATH = os.getenv("DB_PATH", "./data/videos.db")

def save_top_prediction(segment_id, predictions):
    if not predictions:
        return

    # En yüksek skorlu tahmini bul
    top_label = max(predictions, key=predictions.get)
    top_score = round(predictions[top_label], 2)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    description = f"{top_label} detected at {timestamp}"

    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE segment
            SET crime_type = ?, crime_score = ?, description = ?, timestamp = ?
            WHERE segment_id = ?
        """, (top_label, top_score, description, timestamp, segment_id))
        conn.commit()
        conn.close()
        print(f"📝 Segment updated: {segment_id} → {top_label} ({top_score}%)")
    except Exception as e:
        print(f"❌ DB update failed: {e}")
