import torch
import tensorrt as trt
import os
from pathlib import Path
from ultralytics import YOLO
from utils.logger import setup_logger  # 🔧 Logger dosyan burada olmalı

TRT_LOGGER = trt.Logger(trt.Logger.WARNING)
logger = setup_logger("convert", "AI_Logs")  # 🔥 convert.log'a yazacak

class ModelConverter:
    def __init__(self):
        self.models_dir = Path("models")
        self.pt_path = self.models_dir / "model.pt"
        self.onnx_path = self.models_dir / "model_1280.onnx"
        self.engine_path = self.models_dir / "model.engine"
        
        self.models_dir.mkdir(exist_ok=True)

    def check_files(self):
        if not self.pt_path.exists():
            raise FileNotFoundError(f"❌ .pt model dosyası bulunamadı: {self.pt_path}")
        return {
            'pt_exists': self.pt_path.exists(),
            'onnx_exists': self.onnx_path.exists(),
            'engine_exists': self.engine_path.exists()
        }

    def export_to_onnx(self):
        try:
            logger.info("▶️ ONNX dönüşümü başlatılıyor...")
            model = YOLO(self.pt_path)
            model.export(
                format="onnx",
                imgsz=(1280, 1280),
                dynamic=True,
                simplify=True,
                opset=16,
                half=False,
                workspace=4
            )
            exported = list(self.models_dir.glob("*.onnx"))
            logger.info(f"📁 Oluşan ONNX dosyaları: {[str(p) for p in exported]}")
            if not exported:
                raise RuntimeError("❌ ONNX export başarısız, dosya oluşmadı.")
            exported[0].rename(self.onnx_path)
            logger.info(f"✅ ONNX modeli oluşturuldu: {self.onnx_path}")
        except Exception as e:
            logger.exception(f"🛑 ONNX export hatası: {e}")
            raise

    def build_engine(self):
        try:
            logger.info("▶️ TensorRT engine oluşturuluyor...")

            builder = trt.Builder(TRT_LOGGER)
            network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
            parser = trt.OnnxParser(network, TRT_LOGGER)
            config = builder.create_builder_config()

            config.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 32)  # 4 GB
            if builder.platform_has_fast_fp16:
                config.set_flag(trt.BuilderFlag.FP16)
                logger.info("⚡ FP16 desteği etkinleştirildi.")

            with open(self.onnx_path, 'rb') as f:
                parsed = parser.parse(f.read())
                if not parsed:
                    logger.error("🧨 ONNX parse başarısız:")
                    for i in range(parser.num_errors):
                        logger.error(f"    ❌ Hata {i}: {parser.get_error(i)}")
                    raise RuntimeError("ONNX parse işlemi başarısız.")

            input_name = network.get_input(0).name
            logger.info(f"📌 ONNX giriş ismi: {input_name}")
            profile = builder.create_optimization_profile()
            profile.set_shape(input_name, (1,3,1280,1280), (1,3,1280,1280), (1,3,1280,1280))
            config.add_optimization_profile(profile)

            engine_data = builder.build_serialized_network(network, config)
            if not engine_data:
                raise RuntimeError("🚫 TensorRT engine oluşturulamadı. `engine_data` None döndü.")

            with open(self.engine_path, "wb") as f:
                f.write(engine_data)
            logger.info(f"✅ TensorRT engine başarıyla kaydedildi: {self.engine_path}")

        except Exception as e:
            logger.exception(f"❌ Engine oluşturma hatası: {e}")
            raise

    def convert(self):
        try:
            files = self.check_files()
            if files['engine_exists']:
                logger.info("⏩ Zaten mevcut bir .engine dosyası bulundu, yeniden oluşturulmadı.")
                return True

            if not files['onnx_exists']:
                logger.warning("⚠️ ONNX dosyası bulunamadı, yeniden oluşturulacak...")
                self.export_to_onnx()
            else:
                logger.info("🔁 Mevcut ONNX dosyası kullanılacak.")

            self.build_engine()
            logger.info("🎉 Tüm dönüşüm işlemleri başarıyla tamamlandı.")
            return True

        except Exception as e:
            logger.error(f"🧯 Dönüşüm işlemi başarısız: {e}")
            return False

if __name__ == "__main__":
    converter = ModelConverter()
    if not converter.convert():
        logger.error("🛑 Engine üretilemedi. Çıkış yapılıyor.")
        exit(1)
