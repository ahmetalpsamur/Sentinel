import sqlite3
from config import Config
from datetime import datetime

def insert_segment(segment):
    conn = sqlite3.connect(Config.DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
    INSERT OR REPLACE INTO segments 
    (segment_id, video_id, start_frame, end_frame, start_time, end_time,
     dominant_class, score, total_frames, positive_frames,
     bounding_boxes, output_path, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        segment["segment_id"],
        segment["video_id"],
        segment["start_frame"],
        segment["end_frame"],
        segment["start_time"],
        segment["end_time"],
        segment["dominant_class"],
        segment["score"],
        segment["total_frames"],
        segment["positive_frames"],
        segment["bounding_boxes"],
        segment["output_path"],
        datetime.now().isoformat()
    ))

    conn.commit()
    conn.close()
    print(f"🎬 Segment kaydedildi: {segment['segment_id']}")


def segment_for_ui(segment):
    conn = sqlite3.connect(Config.DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
    INSERT OR REPLACE INTO segment 
    (segment_id, url, description, weapon_score, crime_type, weapon_type,latitude,longitude,timestamp)
    VALUES (?, ?,?, ?, ?, ?, ?, ?,?)
    """, (
        segment["segment_id"],
        segment.get("url", ""),
        segment.get("description", ""),
        segment.get("weapon_score", 0.0),
        segment.get("crime_type", ""),
        segment.get("weapon_type", "unknown"),
        segment.get("latitude",""),
        segment.get("longitude",""),
        datetime.now().isoformat()
    ))

    conn.commit()
    conn.close()
    print(f"🎬 Segment kaydedildi: {segment['segment_id']}")

def get_video_resolution(video_id):
    import sqlite3
    conn = sqlite3.connect(Config.DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT width, height FROM video_metadata WHERE video_id = ?", (video_id,))
    result = cursor.fetchone()
    conn.close()
    return (result[0], result[1]) if result else (None, None)