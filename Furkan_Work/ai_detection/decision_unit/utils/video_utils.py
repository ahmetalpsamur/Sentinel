import sqlite3
from config import Config

def get_video_metadata(video_id):
    conn = sqlite3.connect(Config.DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM video_metadata WHERE video_id = ?", (video_id,))
    row = cursor.fetchone()
    keys = [d[0] for d in cursor.description]
    conn.close()
    return dict(zip(keys, row)) if row else None
