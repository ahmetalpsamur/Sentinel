import redis
import os
from utils.logger import setup_logger

logger = setup_logger()

def get_redis_client():
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    REDIS_DB = int(os.getenv("REDIS_DB", 0))

    try:
        client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB)
        client.ping()
        logger.info("✅ Redis bağlantısı başarılı")
        return client
    except redis.ConnectionError as e:
        logger.error(f"❌ Redis'e bağlanılamadı: {e}")
        return None
