import torch
from ultralytics import YOLO
from config import Config
import logging
import time
from utils.logger import setup_logger

logger = setup_logger("model_service")

class ModelService:
    def __init__(self):
        self.config = Config()
        self.device = self._get_device()
        self.model = self._load_model()
    
    def _get_device(self):
        """Kullanılacak cihazı belirler"""
        device = 'cuda:0' if torch.cuda.is_available() else 'cpu'
        logger.info(f"[ModelService] Using device: {device}")
        return device
    
    def _load_model(self):
        """YOLO modelini yükler"""
        try:
            logger.info(f"[ModelService] Loading model from: {self.config.MODEL_PATH}")
            model = YOLO(self.config.MODEL_PATH).to(self.device)
            logger.info(f"[ModelService] Model loaded successfully on {self.device}")
            return model
        except Exception as e:
            logger.exception(f"[ModelService] ❌ Model loading failed: {e}")
            raise
    
    def predict(self, frame):
        """Görüntüde tahmin yapar"""
        try:
            logger.debug("[ModelService] Starting prediction")
            start_time = time.time()
            logger.debug(f"Start time: {start_time}")
            
            results = self.model(frame, device=self.device)[0]
            duration = time.time() - start_time
            
            boxes = results.boxes.xyxy
            confs = results.boxes.conf
            class_ids = results.boxes.cls

            logger.info(f"[ModelService] Prediction completed in {duration:.2f}s — {len(boxes) if boxes is not None else 0} box(es) found")

            class_map = {
                0: "knife",
                1: "pistol"
            }

            predictions = []
            if boxes is not None:
                for box, conf, cid in zip(boxes.cpu().tolist(), confs.cpu().tolist(), class_ids.cpu().tolist()):
                    predictions.append({
                        "box": box,
                        "confidence": conf,
                        "weapon_type": class_map.get(int(cid), "unknown")
                    })

            logger.info(f"[ModelService] Predictions: {predictions}")
            return predictions

        except Exception as e:
            logger.exception(f"[ModelService] 🔴 Prediction failed: {e}")
            return []

