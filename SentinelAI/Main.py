from ultralytics import YOLO
import cv2
import time

model = YOLO('BerkayV1.pt')

cap = cv2.VideoCapture(0)

prev_time = 0
class_names = model.names

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # 📈 GÖRSEL BOYUTU BÜYÜTÜLDÜ: 1280
    results = model.predict(
        source=frame,
        conf=0.4,
        iou=0.4,
        imgsz=1280,  # yüksek çözünürlük
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
        x1, y1, x2, y2 = map(int, box.xyxy[0])

        cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(annotated_frame, label, (x1, y1 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    curr_time = time.time()
    fps = 1 / (curr_time - prev_time) if prev_time != 0 else 0
    prev_time = curr_time

    cv2.putText(annotated_frame, f"FPS: {fps:.2f}", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)

    cv2.imshow("YOLOv8 Live Detection", annotated_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()


"""


# İki farklı modeli yükle
model1 = YOLO("yolov8l.pt")  # Large model, COCO dataset ile eğitilmiş
model2 = YOLO("bestGun.pt")  # Silah tespiti için özel model

# Ekran yakalama için mss başlat
sct = mss.mss()
mon = sct.monitors[1]

# Pencere ayarları (Çeyrek ekran boyutunda aç)
window_name = "Multi YOLO Detection"
cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
cv2.resizeWindow(window_name, mon["width"] // 2, mon["height"] // 2)

while True:
    # Ekran görüntüsünü al
    screen = sct.grab(mon)

    # Görüntüyü numpy array'e çevir ve renk dönüşümü yap
    frame = np.array(screen)
    frame = cv2.cvtColor(frame, cv2.COLOR_BGRA2BGR)

    # İlk modelin tahmini (Genel nesne tanıma)
    results1 = model1.predict(frame, imgsz=1280, conf=0.3, iou=0.3)

    # İkinci modelin tahmini (Silah tespiti)
    results2 = model2.predict(frame, imgsz=1280, conf=0.25, iou=0.3)

    # Sonuçları çizebilmek için görüntüyü kopyala
    output_frame = frame.copy()

    # İlk modelin tespit ettiği nesneleri çiz
    for result in results1:
        output_frame = result.plot()

    # İkinci modelin tespit ettiği nesneleri çiz
    for result in results2:
        output_frame = result.plot()

    # OpenCV ile göster
    cv2.imshow(window_name, output_frame)

    # Çıkış için ESC tuşuna bas
    if cv2.waitKey(1) & 0xFF == 27:
        break

cv2.destroyAllWindows()
"""