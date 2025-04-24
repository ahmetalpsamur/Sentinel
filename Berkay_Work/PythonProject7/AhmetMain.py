from ultralytics import YOLO
import cv2
import numpy as np

# YOLOv8 modelini yükle
model = YOLO('v8Models/reSizedV1.pt')

# Görseli yükle
image_path = 'Test_Photo/nonSized.jpeg'
image = cv2.imread(image_path)

# 📐 Görseli orantılı olarak yeniden boyutlandır ve kenarları yansıt
def resize_with_reflect(image, target_size=(1280, 720)):
    ih, iw = image.shape[:2]
    tw, th = target_size
    scale = min(tw / iw, th / ih)
    nw, nh = int(iw * scale), int(ih * scale)

    # 1. Oranı bozmadan yeniden boyutlandır
    resized = cv2.resize(image, (nw, nh))

    # 2. Pad miktarlarını hesapla
    top = (th - nh) // 2
    bottom = th - nh - top
    left = (tw - nw) // 2
    right = tw - nw - left

    # 3. Reflect padding ile tam 1280x720 yap
    padded = cv2.copyMakeBorder(
        resized, top, bottom, left, right,
        borderType=cv2.BORDER_REFLECT
    )
    return padded

# 🔁 Reflect padding ile yeniden boyutlandır
resized_image = resize_with_reflect(image)

# 🔍 YOLO ile tahmin yap
results = model.predict(
    source=resized_image,
    conf=0.4,
    iou=0.4,
    imgsz=1280,
    show=False,
    verbose=False
)

# 🎯 Tahminleri işle
result = results[0]
boxes = result.boxes
class_names = model.names
annotated = resized_image.copy()

for box in boxes:
    cls_id = int(box.cls[0])
    conf = float(box.conf[0])
    label = f"{class_names[cls_id]}: %{conf * 100:.1f}"

    print(label)

    x1, y1, x2, y2 = map(int, box.xyxy[0])
    cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 255, 0), 2)
    cv2.putText(annotated, label, (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

# 🖼️ Sonucu göster
cv2.imshow("YOLOv8 Detection", annotated)
cv2.waitKey(0)
cv2.destroyAllWindows()
