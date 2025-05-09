# 1. Hafif ama yeterli bir Python imajı
FROM python:3.10-slim

# 2. Sistem bağımlılıklarını kur
RUN apt-get update && apt-get install -y \
    libglib2.0-0 libsm6 libxext6 libxrender-dev gcc && \
    rm -rf /var/lib/apt/lists/*

# 3. Çalışma dizini ayarla
WORKDIR /app

# 4. requirements.txt'i önce kopyala (sadece bu dosya!)
COPY requirements.txt .

# 5. pip install'ı önden yap (bu layer cache'lenir!)
RUN pip install --no-cache-dir -r requirements.txt

# 6. Geri kalan tüm dosyaları ekle (sadece bu değişirse yukarısı tekrar etmez)
COPY . .

# 7. Giriş noktası
CMD ["python", "ai_unit_consumer.py"]
