import sqlite3
import os

DB_PATH = os.getenv("DB_PATH", "./data/videos.db")

def create_tables():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Video metadata tablosu
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS video_metadata (
        video_id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        fps REAL,
        width INTEGER,
        height INTEGER,
        total_frames INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """)

    # Segment tablosu
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS segments (
        segment_id TEXT PRIMARY KEY,
        video_id TEXT NOT NULL,
        start_frame INTEGER,
        end_frame INTEGER,
        start_time REAL,
        end_time REAL,
        dominant_class TEXT,
        score REAL,
        total_frames INTEGER,
        positive_frames INTEGER,
        bounding_boxes TEXT,
        output_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,

        FOREIGN KEY(video_id) REFERENCES video_metadata(video_id)
    )
    """)

    conn.commit()
    conn.close()
    print("✅ Database initialized at", DB_PATH)

if __name__ == "__main__":
    create_tables()
