import redis
import os

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

try:
    redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB)
    redis_client.ping()
    print("✅ Redis bağlantısı başarılı")
except redis.ConnectionError as e:
    print(f"❌ Redis'e bağlanılamadı: {e}")
    redis_client = None
