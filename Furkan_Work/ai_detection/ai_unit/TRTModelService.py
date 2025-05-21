import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
import numpy as np
import cv2
from collections import defaultdict
from utils.logger import setup_logger



class TRTModelService:
    def __init__(self, engine_path):
        self.engine_path = engine_path
        self.trt_logger = trt.Logger(trt.Logger.WARNING)
        self.logger = setup_logger("TRT_model_service")
        self._load_engine()

    def _load_engine(self):
        with open(self.engine_path, "rb") as f, trt.Runtime(self.trt_logger) as runtime:
            self.engine = runtime.deserialize_cuda_engine(f.read())
        self.context = self.engine.create_execution_context()
        self.input_binding_idx = self.engine.get_binding_index("images")
        self.output_binding_idx = self.engine.get_binding_index("output0")

        for i in range(self.engine.num_bindings):
            name = self.engine.get_binding_name(i)
            shape = self.engine.get_binding_shape(i)
            is_input = self.engine.binding_is_input(i)
            self.logger.info(f"[TRT] Binding {i}: name={name}, shape={shape}, is_input={is_input}")

        self.logger.info("[TRT] Engine loaded and context created.")

    def predict(self, frame):
        try:
            # 🔧 1. Preprocess
            input_image = cv2.resize(frame, (1280,720))           
            input_image = input_image.astype(np.float32) 
            input_image = np.transpose(input_image, (2, 0, 1))  # CHW
            input_image = np.expand_dims(input_image, axis=0)  # NCHW
            input_image = np.ascontiguousarray(input_image)

            self.context.set_binding_shape(self.input_binding_idx, input_image.shape)

            input_nbytes = input_image.nbytes
            output_shape = self.context.get_binding_shape(self.output_binding_idx)
            output = np.empty(output_shape, dtype=np.float32)
            output_nbytes = output.nbytes

            d_input = cuda.mem_alloc(input_nbytes)
            d_output = cuda.mem_alloc(output_nbytes)

            cuda.memcpy_htod(d_input, input_image)
            bindings = [int(d_input), int(d_output)]

            # 🚀 2. Run inference
            self.context.execute_v2(bindings)
            cuda.memcpy_dtoh(output, d_output)
            output = output.reshape(output_shape)

            # 🧠 3. Postprocess (convert to predictions[])
            predictions = []
            class_map = {0: "knife", 1: "pistol"}  # Güncel class map

            for i in range(output.shape[2]):
                conf = output[0, 4, i]
                if conf > 0.25:  # Eşik değeri
                    x_center = output[0, 0, i]
                    y_center = output[0, 1, i]
                    w = output[0, 2, i]
                    h = output[0, 3, i]
                    x1 = x_center - w / 2
                    y1 = y_center - h / 2
                    x2 = x_center + w / 2
                    y2 = y_center + h / 2
                    class_id = int(output[0, 5, i])

                    predictions.append({
                        "box": [float(x1), float(y1), float(x2), float(y2)],
                        "confidence": float(conf),
                        "weapon_type": class_map.get(class_id, "unknown")
                    })

            self.logger.info(f"[TRTModelService] {len(predictions)} prediction(s) completed.")
            return predictions

        except Exception as e:
            self.logger.exception(f"[TRTModelService] 🔴 Prediction failed: {e}")
            return []

