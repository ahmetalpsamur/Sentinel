from ultralytics import YOLO
import cv2


model = YOLO('v8Models/BerkayV1.pt')


video_path = 'TestVideo/Video2.mp4'  # değiştirilebilir
cap = cv2.VideoCapture(video_path)

class_names = model.names

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break


    results = model.predict(
        source=frame,
        conf=0.4,
        iou=0.4,
        imgsz=1280,
        show=False,
        verbose=False
    )

    result = results[0]
    boxes = result.boxes
    annotated_frame = frame.copy()

    for box in boxes:
        cls_id = int(box.cls[0])
        conf = float(box.conf[0])
        label = f"{class_names[cls_id]}: %{conf * 100:.1f}"

        print(label)

        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(annotated_frame, label, (x1, y1 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)


    cv2.imshow("YOLOv8 Video Detection", annotated_frame)


    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
