import os

class Config:
    BUFFER_TIMEOUT = int(os.getenv("BUFFER_TIMEOUT", 5)) 
    # Segment oluşturma parametreleri
    SEGMENT_WINDOW_SIZE = 30          # Sliding window boyutu (frame cinsinden)
    SEGMENT_MIN_DETECTIONS = 10       # Segment oluşturmak için minimum tespit sayısı
    SEGMENT_PADDING_SECONDS = 2       # Segment başlangıç/bitişine eklenecek padding süresi (saniye)
    # Timeout base süresi (düşük FPS'li videolar için)
    BASE_TIMEOUT_SECONDS = 15  
    # Her FPS birimi için eklenecek süre (saniye/FPS)
    TIMEOUT_PER_FPS = 0.25  

    # Segment birleştirme için maksimum ara (frame cinsinden)
    SEGMENT_MERGE_GAP = 45

    # Baz eşik değeri (30 frame'lik segment için)
    BASE_MIN_DETECTIONS = 10  
    # Frame başına ek eşik (0.3 => 100 frame'lik segment için 10 + (100*0.3)=40)
    DETECTION_PER_FRAME = 0.3 
    
    # Video codec ayarları
    SEGMENT_INPUT_CODEC = "MJPG"      # Girdi video codec (fourcc formatında)
    SEGMENT_OUTPUT_CODEC = "libx264"  # Çıktı video codec
    SEGMENT_FFMPEG_PRESET = "veryfast"# FFmpeg encode preset
    SEGMENT_FFMPEG_CRF = 23           # FFmpeg CRF değeri
    
    # Model ve görüntü işleme
    MODEL_INPUT_SHAPE = (416, 416)    # Modelin beklediği girdi boyutu (height, width)

    # Diğer Ayarlar
    DB_PATH = os.path.join("data", "videos.db")
    INPUT_TOPIC = "ai_results"
    OUTPUT_TOPUC = "segment_videos"
    KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
    BACKEND_HOST = "192.168.1.75"
    BACKEND_PORT = 8000
