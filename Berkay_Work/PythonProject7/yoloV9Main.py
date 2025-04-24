import torch
import cv2
from pathlib import Path
import numpy as np

# 📦 Modeli yükle (YOLOv5 formatında)
model = torch.hub.load('ultralytics/yolov5', 'custom', path='v8Models/epoch5Yolov9.pt', force_reload=True)

# 🎥 Kamera başlat
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 736)

while True:
    ret, frame = cap.read()
    if not ret:
        print("Kamera verisi alınamadı.")
        break

    # YOLOv5 modeline tahmin yaptır
    results = model(frame)

    # Tahmin sonuçlarını çizdir
    annotated_frame = results.render()[0]

    # Göster
    cv2.imshow("YOLOv5 Detection - Webcam", annotated_frame)

    # Çıkmak için 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# 🧹 Temizlik
cap.release()
cv2.destroyAllWindows()
