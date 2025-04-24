from ultralytics import YOLO
import cv2

# YOLOv8 modelini yükle
model = YOLO('v8Models/reSizedV1.pt')

# Görseli yükle
image_path = 'Test_Photo/nonSized.jpeg'  # kendi görselinin yolu
frame = cv2.imread(image_path)

# Tahmin yap
results = model.predict(
    source=frame,
    conf=0.4,
    iou=0.4,
    imgsz=1280,
    show=False,
    verbose=False
)

# Sonuçları işle
result = results[0]
boxes = result.boxes
class_names = model.names
annotated_frame = frame.copy()

for box in boxes:
    cls_id = int(box.cls[0])
    conf = float(box.conf[0])
    label = f"{class_names[cls_id]}: %{conf * 100:.1f}"

    # ✨ Sonucu konsola yaz
    print(label)

    x1, y1, x2, y2 = map(int, box.xyxy[0])
    cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
    cv2.putText(annotated_frame, label, (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

# Görseli göster
cv2.imshow("YOLOv8 Image Detection", annotated_frame)
cv2.waitKey(0)
cv2.destroyAllWindows()
