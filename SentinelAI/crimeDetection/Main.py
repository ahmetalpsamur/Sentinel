import cv2
import tkinter as tk
from tkinter import filedialog, messagebox
from ultralytics import YOLO
import os

# Fonksiyonlar (daha önce tanımladığın fonksiyonlar biraz sadeleştirildi)

def detect_objects_in_photo_gui(image_path):
    image_orig = cv2.imread(image_path)
    yolo_model = YOLO('./Models/knifeModel(epoc=50,img=1280,8000).pt')
    results = yolo_model(image_orig)

    for result in results:
        classes = result.names
        cls = result.boxes.cls
        conf = result.boxes.conf
        detections = result.boxes.xyxy

        for pos, detection in enumerate(detections):
            if conf[pos] >= 0.5:
                xmin, ymin, xmax, ymax = detection
                confidence_percent = conf[pos] * 100
                label = f"{classes[int(cls[pos])]} {confidence_percent:.1f}%"
                color = (0, int(cls[pos]) * 20 % 256, 255)
                cv2.rectangle(image_orig, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                cv2.putText(image_orig, label, (int(xmin), int(ymin) - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1, cv2.LINE_AA)

    result_path = "./Results/result.jpg"
    os.makedirs("./Results", exist_ok=True)
    cv2.imwrite(result_path, image_orig)
    messagebox.showinfo("Fotoğraf İşlendi", f"Kaydedildi: {result_path}")

def detect_objects_in_video_gui(video_path):
    yolo_model = YOLO('./Models/knifeModel(epoc=50,img=1280,4000).pt')
    video_capture = cv2.VideoCapture(video_path)

    width = int(video_capture.get(3))
    height = int(video_capture.get(4))
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    result_video_path = "./Results/result_video.avi"
    os.makedirs("./Results", exist_ok=True)
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
                    label = f"{classes[int(cls[pos])]} {conf[pos]*100:.1f}%"
                    color = (0, int(cls[pos]) * 20 % 256, 255)
                    cv2.rectangle(frame, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                    cv2.putText(frame, label, (int(xmin), int(ymin) - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1, cv2.LINE_AA)

        out.write(frame)

    video_capture.release()
    out.release()
    messagebox.showinfo("Video İşlendi", f"Kaydedildi: {result_video_path}")

def detect_objects_from_camera_gui():
    video_capture = cv2.VideoCapture(0)
    yolo_model = YOLO('./Models/yolov8-kg-best.pt')
    if not video_capture.isOpened():
        messagebox.showerror("Hata", "Kamera açılamadı!")
        return

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
                    label = f"{classes[int(cls[pos])]} {conf[pos]*100:.1f}%"
                    color = (0, int(cls[pos]) * 20 % 256, 255)
                    cv2.rectangle(frame, (int(xmin), int(ymin)), (int(xmax), int(ymax)), color, 2)
                    cv2.putText(frame, label, (int(xmin), int(ymin) - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1, cv2.LINE_AA)

        cv2.imshow("Kamera ile Nesne Tespiti", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    video_capture.release()
    cv2.destroyAllWindows()

# GUI Arayüzü

def select_photo():
    file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png *.jpeg")])
    if file_path:
        detect_objects_in_photo_gui(file_path)

def select_video():
    file_path = filedialog.askopenfilename(filetypes=[("Video files", "*.mp4 *.avi")])
    if file_path:
        detect_objects_in_video_gui(file_path)

def open_camera():
    detect_objects_from_camera_gui()

# Arayüz Oluştur
root = tk.Tk()
root.title("YOLOv8 Nesne Tespiti")
root.geometry("400x250")

title = tk.Label(root, text="YOLOv8 Object Detection GUI", font=("Helvetica", 16, "bold"))
title.pack(pady=10)

btn1 = tk.Button(root, text="📷 Fotoğraf Seç ve Tespit Et", command=select_photo, height=2, width=30)
btn1.pack(pady=5)

btn2 = tk.Button(root, text="🎞️ Video Seç ve Tespit Et", command=select_video, height=2, width=30)
btn2.pack(pady=5)

btn3 = tk.Button(root, text="📡 Kameradan Gerçek Zamanlı Tespit", command=open_camera, height=2, width=30)
btn3.pack(pady=5)

root.mainloop()





