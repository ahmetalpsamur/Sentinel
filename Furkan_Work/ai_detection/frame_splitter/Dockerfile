FROM python:3.12

WORKDIR /app

# OpenCV için sistem bağımlılıklarını kur
RUN apt-get update && apt-get install -y libgl1

COPY . .

ENV PYTHONPATH="${PYTHONPATH}:/app/shared"


RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "frame_splitter.py"]
