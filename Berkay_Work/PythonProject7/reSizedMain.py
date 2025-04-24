import ultralytics
from ultralytics import YOLO
import cv2
import time

model = YOLO('v8Models/reSizedV1.pt')
cap = cv2.VideoCapture(0)

prev_time = 0
class_names = model.names

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # 📏 Görseli 720p çözünürlüğe ölçekle
    frame_resized = cv2.resize(frame, (1280, 720))

    results = model.predict(
        source=frame_resized,
        conf=0.4,
        iou=0.4,
        imgsz=1280,
        show=False,
        verbose=False
    )

    result = results[0]
    boxes = result.boxes
    annotated_frame = frame_resized.copy()

    for box in boxes:
        cls_id = int(box.cls[0])
        conf = float(box.conf[0])
        label = f"{class_names[cls_id]}: %{conf * 100:.1f}"
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(annotated_frame, label, (x1, y1 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    curr_time = time.time()
    fps = 1 / (curr_time - prev_time) if prev_time else 0
    prev_time = curr_time

    cv2.putText(annotated_frame, f"FPS: {fps:.2f}", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)

    cv2.imshow("YOLOv8 720p Detection", annotated_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
