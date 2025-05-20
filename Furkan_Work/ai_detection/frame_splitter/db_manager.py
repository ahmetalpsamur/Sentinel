import sqlite3
import os
from datetime import datetime

DB_PATH = os.getenv("DB_PATH", "./data/videos.db")

def insert_video_metadata(video_id, path, fps, width, height, total_frames):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
    INSERT OR REPLACE INTO video_metadata 
    (video_id, path, fps, width, height, total_frames, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (video_id, path, fps, width, height, total_frames, datetime.now().isoformat()))

    conn.commit()
    conn.close()
    print(f"📼 Video metadata eklendi: {video_id}")