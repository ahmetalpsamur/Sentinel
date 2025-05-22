FROM nvcr.io/nvidia/tensorrt:23.06-py3

WORKDIR /app

RUN apt-get update && apt-get install -y git ffmpeg libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir ultralytics==8.3.141

COPY . .

CMD ["python", "build_engine.py"]
