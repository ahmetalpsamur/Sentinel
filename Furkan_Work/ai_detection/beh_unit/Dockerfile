# NVIDIA CUDA 11.8 tabanlı imaj
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Gerekli sistem paketleri
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3-dev \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Python 3.10'u default yap
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# pip ve araçları güncelle
RUN python -m pip install --upgrade pip setuptools wheel

# Çalışma dizini
WORKDIR /app

# Gereksinimler: önce PyTorch + CUDA
COPY requirements.txt .
RUN pip install --no-cache-dir \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Diğer Python bağımlılıkları
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyalarını kopyala
COPY . .

# Klasör oluştur ve izin ver
RUN mkdir -p /app/logs /app/frames /app/data /app/Beh_log && chmod -R a+rw /app

# Ortam değişkenleri
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV NVIDIA_VISIBLE_DEVICES=all

# Başlatma
CMD ["python", "consumer.py"]
