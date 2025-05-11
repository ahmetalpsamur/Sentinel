import os

class Config:
    INPUT_TOPIC = "ai_results"
    BUFFER_TIMEOUT = 3

    DB_PATH = os.path.join( "data", "videos.db")

    INPUT_TOPIC = "ai_results"
    KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")