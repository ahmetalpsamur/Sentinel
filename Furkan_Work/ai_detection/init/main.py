# kafka_init/main.py
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError
import sqlite3
import os


TOPICS = {
    "video_uploaded": 1,
    "uploaded_video_beh": 1,
    "to_ai_unit": 4,
    "ai_results": 1,
    "segment_videos":1,
}

def create_topics():
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
    admin_client = KafkaAdminClient(bootstrap_servers=bootstrap_servers)
    existing_topics = admin_client.list_topics()

    topics_to_create = []
    for topic, partitions in TOPICS.items():
        if topic not in existing_topics:
            topics_to_create.append(NewTopic(
                name=topic,
                num_partitions=partitions,
                replication_factor=1
            ))

    if topics_to_create:
        try:
            admin_client.create_topics(topics_to_create)
            print(f"[KafkaInit] Created topics: {[t.name for t in topics_to_create]}")
        except TopicAlreadyExistsError:
            print("[KafkaInit] Some topics already exist.")
    else:
        print("[KafkaInit] All topics already exist.")

    admin_client.close()


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
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS segment(
        segment_id TEXT PRIMARY KEY,
        url TEXT,
        description TEXT,
        weapon_score REAL,
        crime_score REAL,        
        crime_type TEXT,
        weapon_type TEXT,  
        reported BOOLEAN DEFAULT FALSE,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP   
    )
    """)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS video_predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id TEXT NOT NULL,
        video_path TEXT NOT NULL,
        top1_label TEXT NOT NULL,
        top1_confidence REAL NOT NULL,
        top2_label TEXT,
        top2_confidence REAL,
        top3_label TEXT,
        top3_confidence REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """)
    conn.commit()
    conn.close()
    print("✅ Database initialized at", DB_PATH)
    
if __name__ == "__main__":
    create_topics()
    create_tables()
