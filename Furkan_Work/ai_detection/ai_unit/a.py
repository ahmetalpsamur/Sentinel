import os
from ultralytics import YOLO

base_dir = os.path.dirname(__file__)
model_path = os.path.join(base_dir, "models", "reSizedV1.pt")

model = YOLO(model_path)
print("✅ Model başarıyla yüklendi.")
