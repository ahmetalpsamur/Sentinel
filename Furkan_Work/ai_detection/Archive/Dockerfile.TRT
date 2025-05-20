# CUDA 11.4/11.5 ile uyumlu TensorRT 8.3.1 içeren resmi NVIDIA imajı
FROM nvcr.io/nvidia/tensorrt:23.06-py3

# Çalışma dizini
WORKDIR /app

# Sistem bağımlılıkları (OpenCV ve FFmpeg için gerekli)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
# Python bağımlılıkları (önce requirements.txt)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# TensorRT destekli inference için PyCUDA, Polygraphy ve yardımcılar
RUN pip install --no-cache-dir pycuda polygraphy colored

# Uygulama dosyalarını kopyala
COPY . .

# Gerekli klasörler ve izinler
RUN mkdir -p /app/logs /app/frames && chmod -R a+rw /app/logs /app/frames

# Ortam değişkenleri
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV NVIDIA_VISIBLE_DEVICES=all

# Giriş noktası
CMD ["python", "main.py"]
