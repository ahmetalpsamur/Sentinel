import cv2
import numpy as np
import base64
import os
from config import Config
from utils.logger import setup_logger

logger = setup_logger("image_processor")

class ImageProcessor:
    def __init__(self):
        self.config = Config()
        os.makedirs(self.config.FRAME_SAVE_PATH, exist_ok=True)
    
    def encode_image(self, frame):
        """OpenCV frame'i base64'e çevirir"""
        _, buffer = cv2.imencode('.jpg', frame)
        return base64.b64encode(buffer).decode('utf-8')
    
    def decode_image(self, b64_string):
        """Base64'ü OpenCV frame'e çevirir"""
        try:
            img_data = base64.b64decode(b64_string)
            np_arr = np.frombuffer(img_data, np.uint8)
            return cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        except Exception as e:
            logger.error(f"Image decode error: {e}")
            return None
    
    def draw_boxes(self, image, boxes):
        """Tespit edilen kutuları çizer"""
        for box in boxes:
            x1, y1, x2, y2 = map(int, box)
            cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
        return image
    
    def save_image(self, image, frame_id):
        """Görüntüyü diske kaydeder"""
        logger.info(f"Image saved. {frame_id}")
        save_path = os.path.join(self.config.FRAME_SAVE_PATH, f"{frame_id}.jpg")
        cv2.imwrite(save_path, image)
        return save_path