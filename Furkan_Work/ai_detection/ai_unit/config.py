import os

class Config:
    # Kafka Ayarları
    KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
    INPUT_TOPIC = "to_ai_unit"
    OUTPUT_TOPIC = "ai_results"
    
    # Redis Ayarları
    REDIS_HOST = os.getenv("REDIS_HOST", "redis")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    REDIS_DB = int(os.getenv("REDIS_DB", 0))
    
    # Model Ayarları
    MODEL_PATH = os.path.join(os.path.dirname(__file__), "models", "model.pt")
    FRAME_SAVE_PATH = "frames"
    
    # Sistem Ayarları
    MAX_RETRIES = 5
    RETRY_DELAY = 5