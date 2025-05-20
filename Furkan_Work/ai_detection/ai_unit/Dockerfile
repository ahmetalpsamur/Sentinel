# NVIDIA CUDA 11.8 temel imajı
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Sistem bağımlılıkları
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

# Python 3.10'u varsayılan yap
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Pip'i güncelle
RUN python -m pip install --upgrade pip setuptools wheel

# Çalışma dizini
WORKDIR /app

# Bağımlılıkları yükle (önce PyTorch)
COPY requirements.txt .
RUN pip install --no-cache-dir \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Sonra diğer bağımlılıklar
RUN pip install --no-cache-dir -r requirements.txt ultralytics==8.2.103

# Uygulama dosyalarını kopyala
COPY . .

# Log ve frame dizinleri
RUN mkdir -p /app/logs /app/frames && chmod -R a+rw /app/logs /app/frames

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV NVIDIA_VISIBLE_DEVICES=all

CMD ["python", "main.py"]