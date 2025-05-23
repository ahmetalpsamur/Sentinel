import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
import numpy as np
import cv2
import time
from utils.logger import setup_logger

class TRTModelService:
    def __init__(self, engine_path):
        self.engine_path = engine_path
        self.trt_logger = trt.Logger(trt.Logger.WARNING)
        self.logger = setup_logger("TRT_model_service")
        self.input_size = 1280
        self.class_map = {0: "knife", 1: "pistol"}
        self.conf_threshold = 0.3
        self._load_engine()
        self._prepare_buffers()

    def _load_engine(self):
        with open(self.engine_path, "rb") as f, trt.Runtime(self.trt_logger) as runtime:
            self.engine = runtime.deserialize_cuda_engine(f.read())
        self.context = self.engine.create_execution_context()
        self.input_binding_idx = self.engine.get_binding_index("images")
        self.output_binding_idx = self.engine.get_binding_index("output0")
        self.logger.info("[TRT] Engine başarıyla yüklendi.")

    def _prepare_buffers(self):
        self.input_shape = self.engine.get_binding_shape(self.input_binding_idx)
        self.output_shape = self.engine.get_binding_shape(self.output_binding_idx)

        input_nbytes = int(np.prod(self.input_shape)) * 4
        output_nbytes = int(np.prod(self.output_shape)) * 4

        self.d_input = cuda.mem_alloc(input_nbytes)
        self.d_output = cuda.mem_alloc(output_nbytes)

        self.bindings = [int(self.d_input), int(self.d_output)]
        self.stream = cuda.Stream()

    def _preprocess(self, frame):
        h, w = frame.shape[:2]
        scale = min(self.input_size / h, self.input_size / w)
        new_h, new_w = int(h * scale), int(w * scale)

        resized = cv2.resize(frame, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
        canvas = np.full((self.input_size, self.input_size, 3), 114, dtype=np.uint8)
        canvas[:new_h, :new_w] = resized

        img = canvas.astype(np.float32)  # normalize ETME — YOLOv8 engine FP32 raw beklentili
        img = np.transpose(img, (2, 0, 1))  # CHW
        img = np.expand_dims(img, axis=0)  # NCHW
        return np.ascontiguousarray(img), (h, w), scale

    def _postprocess(self, output, original_shape, scale):
        predictions = []
        detections = output[0]  # shape: (6, 33600)

        if detections.shape[0] != 6:
            self.logger.warning(f"[TRT] Beklenmeyen çıkış şekli: {detections.shape}")
            return predictions

        detections = detections.transpose()  # (6, 33600) → (33600, 6)

        for det in detections:
            x1, y1, x2, y2, conf, class_id = det

            if conf < self.conf_threshold:
                continue

            if x2 <= x1 or y2 <= y1:
                continue

            # Ölçekleme
            x1 = max(0, min(int(x1 / scale), original_shape[1]))
            y1 = max(0, min(int(y1 / scale), original_shape[0]))
            x2 = max(0, min(int(x2 / scale), original_shape[1]))
            y2 = max(0, min(int(y2 / scale), original_shape[0]))

            predictions.append({
                "box": [float(x1), float(y1), float(x2), float(y2)],
                "confidence": float(conf),
                "weapon_type": self.class_map.get(int(class_id), "unknown")
            })

        return predictions

    def predict(self, frame):
        try:
            start_time = time.time()
            input_image, original_shape, scale = self._preprocess(frame)

            cuda.memcpy_htod_async(self.d_input, input_image, self.stream)
            self.context.execute_async_v2(bindings=self.bindings, stream_handle=self.stream.handle)
            output = np.empty(self.output_shape, dtype=np.float32)
            cuda.memcpy_dtoh_async(output, self.d_output, self.stream)
            self.stream.synchronize()

            predictions = self._postprocess(output, original_shape, scale)
            self.logger.info(f"[TRT] Tahmin süresi: {time.time() - start_time:.2f}s - {len(predictions)} nesne bulundu")
            return predictions

        except Exception as e:
            self.logger.exception(f"[TRT] Hata: {e}")
            return []
