FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    gcc \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app/               


RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "main.py"]
