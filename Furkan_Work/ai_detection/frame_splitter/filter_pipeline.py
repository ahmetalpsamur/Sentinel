import cv2
import numpy as np

def adjust_gamma(image, gamma=1.0):
    invGamma = 1.0 / gamma
    table = np.array([(i / 255.0) ** invGamma * 255 for i in range(256)]).astype("uint8")
    return cv2.LUT(image, table)

def is_dark(frame, threshold=50):
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    return np.mean(gray) < threshold

def sharpen_image(image):
    kernel = np.array([[0, -1, 0],
                       [-1, 5,-1],
                       [0, -1, 0]])
    return cv2.filter2D(image, -1, kernel)

def preprocess_frame(frame, target_size=(1280, 720)):
    # 1. Karanlık kontrolü
    dark = is_dark(frame)

    # 2. Işık koşuluna göre işlem
    if dark:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        enhanced = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2BGR)
        gamma_corrected = adjust_gamma(enhanced, gamma=1.5)
        filtered = cv2.bilateralFilter(gamma_corrected, 9, 75, 75)
    else:
        filtered = cv2.GaussianBlur(frame, (3, 3), 0)

    # 3. Keskinleştirme
    sharpened = sharpen_image(filtered)

    # 4. Resize (gerekirse)
    resized = cv2.resize(sharpened, target_size)

    # 5. Normalize (YOLO gibi modeller uint8 ister, bazı modeller float32 ister)
    normalized = resized / 255.0
    frame_float32 = normalized.astype(np.float32)

    return frame_float32