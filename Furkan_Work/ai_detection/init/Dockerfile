FROM python:3.10-slim

WORKDIR /app
COPY main.py .

RUN pip install --no-cache-dir kafka-python

CMD ["python", "main.py"]
