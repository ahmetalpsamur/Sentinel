import cv2
import numpy as np

def is_dark(frame, threshold=40):
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    mean_brightness = np.mean(gray)
    return mean_brightness < threshold

def preprocess_frame(frame, target_size=(416, 416)):
    if is_dark(frame):
        # Karanlık ortam: CLAHE + Bilateral Filter
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        enhanced = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2BGR)
        filtered = cv2.bilateralFilter(enhanced, 9, 75, 75)
    else:
        # Normal ışık: Gaussian Blur
        filtered = cv2.GaussianBlur(frame, (3, 3), 0)

    resized = cv2.resize(filtered, target_size)
    normalized = resized / 255.0
    frame_uint8 = (normalized * 255).astype(np.uint8)

    return frame_uint8
