import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit  # bu CUDA context'i başlatır
import numpy as np
import cv2

class TRTModelService:
    def __init__(self, engine_path):
        self.engine_path = engine_path
        self.logger = trt.Logger(trt.Logger.WARNING)
        self._load_engine()

    def _load_engine(self):
        with open(self.engine_path, "rb") as f, trt.Runtime(self.logger) as runtime:
            self.engine = runtime.deserialize_cuda_engine(f.read())
        self.context = self.engine.create_execution_context()
        self.input_binding_idx = self.engine.get_binding_index("images")
        self.output_binding_idx = self.engine.get_binding_index("output0")

        # Gerekirse logla:
        for i in range(self.engine.num_bindings):
            name = self.engine.get_binding_name(i)
            shape = self.engine.get_binding_shape(i)
            is_input = self.engine.binding_is_input(i)
            print(f"[TRT] Binding {i}: name={name}, shape={shape}, is_input={is_input}")

        print("[TRT] Engine loaded and context created.")

    def predict(self, frame):
        # 1. Preprocess
        input_image = cv2.resize(frame, (1280, 1280))
        input_image = input_image.astype(np.float32) / 255.0
        input_image = np.transpose(input_image, (2, 0, 1))  # CHW
        input_image = np.expand_dims(input_image, axis=0)  # NCHW
        input_image = np.ascontiguousarray(input_image)

        # 2. Dynamic input shape set
        self.context.set_binding_shape(self.input_binding_idx, input_image.shape)

        # 3. Shape & bellek hesaplama
        input_nbytes = input_image.nbytes
        output_shape = self.context.get_binding_shape(self.output_binding_idx)
        output = np.empty(output_shape, dtype=np.float32)
        output_nbytes = output.nbytes

        # 4. GPU belleği ayırma
        d_input = cuda.mem_alloc(input_nbytes)
        d_output = cuda.mem_alloc(output_nbytes)

        # 5. Input verisini kopyala
        cuda.memcpy_htod(d_input, input_image)
        bindings = [int(d_input), int(d_output)]

        # 6. Modeli çalıştır
        self.context.execute_v2(bindings)

        # 7. Output'u çek
        cuda.memcpy_dtoh(output, d_output)
        output = output.reshape(output_shape)

        # 8. Postprocess (YOLOv8 varsayımı: [x, y, w, h, conf, class])
        boxes = []
        confs = []

        for i in range(output.shape[2]):
            conf = output[0, 4, i]
            if conf > 0.25:  # eşik değeri (gerekirse ayarlanabilir)
                x = output[0, 0, i]
                y = output[0, 1, i]
                w = output[0, 2, i]
                h = output[0, 3, i]
                boxes.append([x, y, w, h])
                confs.append(conf)

        return {
            "boxes": boxes,
            "confs": confs
    }

