"""
import cv2
from ultralytics import YOLO


def detect_objects_in_photo(image_path):
    image_orig = cv2.imread(image_path)

    yolo_model = YOLO('./Models/otherProject2.pt')

    results = yolo_model(image_orig)

    for result in results:
        classes = result.names
        cls = result.boxes.cls
        conf = result.boxes.conf
        detections = result.boxes.xyxy

        for pos, detection in enumerate(detections):
            if conf[pos] >= 0.5:
                xmin, ymin, xmax, ymax = detection
                label = f"{classes[int(cls[pos])]} {conf[pos]:.2f}"
                color = (0, int(cls[pos]), 255)
                cv2.rectangle(image_orig, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                cv2.putText(image_orig, label, (int(xmin), int(ymin) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
                            cv2.LINE_AA)

    result_path = "./imgs/Test/teste.jpg"
    cv2.imwrite(result_path, image_orig)
    return result_path


def detect_objects_in_video(video_path):

    yolo_model = YOLO('./Models/knifeModel(epoc=50,img=1280,4000).pt')

    video_capture = cv2.VideoCapture(video_path)
    width = int(video_capture.get(3))
    height = int(video_capture.get(4))
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    result_video_path = "detected_objects_video2.avi"
    out = cv2.VideoWriter(result_video_path, fourcc, 20.0, (width, height))

    while True:
        ret, frame = video_capture.read()
        if not ret:
            break
        results = yolo_model(frame)

        for result in results:
            classes = result.names
            cls = result.boxes.cls
            conf = result.boxes.conf
            detections = result.boxes.xyxy

            for pos, detection in enumerate(detections):
                if conf[pos] >= 0.5:
                    xmin, ymin, xmax, ymax = detection
                    label = f"{classes[int(cls[pos])]} {conf[pos]:.2f}"
                    color = (0, int(cls[pos]), 255)
                    cv2.rectangle(frame, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                    cv2.putText(frame, label, (int(xmin), int(ymin) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
                                cv2.LINE_AA)

        out.write(frame)
    video_capture.release()
    out.release()

    return result_video_path


def detect_objects_and_plot(path_orig):
    image_orig = cv2.imread(path_orig)

    yolo_model = YOLO('./Models/otherProject2.pt')

    results = yolo_model(image_orig)

    for result in results:
        classes = result.names
        cls = result.boxes.cls
        conf = result.boxes.conf
        detections = result.boxes.xyxy

        for pos, detection in enumerate(detections):
            if conf[pos] >= 0.5:
                xmin, ymin, xmax, ymax = detection
                label = f"{classes[int(cls[pos])]} {conf[pos]:.2f}"
                color = (0, int(cls[pos]), 255)
                cv2.rectangle(image_orig, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                cv2.putText(image_orig, label, (int(xmin), int(ymin) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
                            cv2.LINE_AA)

    cv2.imshow("Teste", image_orig)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

def detect_objects_from_camera():
    # Kamerayı aç (0 genellikle varsayılan kameradır, başka bir kameraya erişim için farklı numara kullanılabilir)
    video_capture = cv2.VideoCapture(0)  # Kameranın indeksini buradan değiştirebilirsiniz (örneğin 1, 2 vs.)
    yolo_model = YOLO('./Models/knifeModel(epoc=50,img=1280,4000).pt')
    if not video_capture.isOpened():
        print("Kamera açılamadı!")
        return

    # Kamera çözünürlüğünü al
    width = int(video_capture.get(3))
    height = int(video_capture.get(4))

    # Video kaydını çıkış için ayarla
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    result_video_path = "detected_objects_camera.avi"
    out = cv2.VideoWriter(result_video_path, fourcc, 20.0, (width, height))

    while True:
        # Kameradan bir kare oku
        ret, frame = video_capture.read()
        if not ret:
            break

        # YOLO modelini kullanarak nesne tespiti yap
        results = yolo_model(frame)

        for result in results:
            classes = result.names
            cls = result.boxes.cls
            conf = result.boxes.conf
            detections = result.boxes.xyxy

            for pos, detection in enumerate(detections):
                if conf[pos] >= 0.5:
                    xmin, ymin, xmax, ymax = detection
                    label = f"{classes[int(cls[pos])]} {conf[pos]:.2f}"
                    color = (0, int(cls[pos]), 255)
                    cv2.rectangle(frame, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                    cv2.putText(frame, label, (int(xmin), int(ymin) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
                                cv2.LINE_AA)

        # İşlenmiş kareyi videoya yaz
        out.write(frame)

        # İşlenmiş kareyi ekranda göster
        cv2.imshow("Kamera ile Nesne Tespiti", frame)

        # Çıkmak için 'q' tuşuna basılmasını bekle
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # Kamerayı ve yazıcıyı serbest bırak
    video_capture.release()
    out.release()

    cv2.destroyAllWindows()
    return result_video_path

if __name__ == "__main__":
    # Kullanmak istediğin fonksiyonu çağır
    # Örnek: Fotoğraf üzerinde nesne tespiti
    # photo_path = "deneme.jpg"  # Buraya kendi test fotoğrafını koy
    # result_photo = detect_objects_in_photo(photo_path)
    # print(f"İşlenmiş fotoğraf kaydedildi: {result_photo}")

    # Eğer video denemek istersen:
    video_path = "./TestData/knifeTestVideo.mp4"
    result_video = detect_objects_in_video(video_path)
    print(f"İşlenmiş video kaydedildi: {result_video}")

    #result_video = detect_objects_from_camera()
    #print(f"İşlenmiş video kaydedildi: {result_video}")

    # Eğer sadece görüntü çizdirip ekranda göstermek istersen:
    # detect_objects_and_plot(photo_path)
"""











"""
from ultralytics import YOLO
import cv2
import time

model = YOLO('../Models/knifeModel(epoc=50,img=1280,4000).pt')
#model = YOLO('yolov8n.pt')

cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)  # 720p genişlik
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)  # 720p yükseklik

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
import cv2
from ultralytics import YOLO

model = YOLO('../Models/knifeModel(epoc=50,img=1280,4000).pt')
model.export(format="onnx")