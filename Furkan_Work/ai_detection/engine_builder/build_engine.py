import tensorrt as trt
import torch
from ultralytics import YOLO
from pathlib import Path
import logging

# Log ayarı
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("engine_builder")

TRT_LOGGER = trt.Logger(trt.Logger.WARNING)

# Dosya yolları
models_dir = Path("models")
pt_path = models_dir / "model.pt"
onnx_path = models_dir / "model.onnx"
engine_path = models_dir / "model.engine"

# Klasör kontrolü
models_dir.mkdir(exist_ok=True)

# .pt → .onnx
if not onnx_path.exists():
    if not pt_path.exists():
        logger.error(f"❌ model.pt bulunamadı: {pt_path}")
        exit(1)
    logger.info("▶️ ONNX export başlatılıyor...")
    model = YOLO(str(pt_path))
    model.export(format="onnx", imgsz=(1280, 1280), simplify=False, dynamic=False, half=False)
    exported = list(models_dir.glob("*.onnx"))
    if not exported:
        logger.error("🧨 ONNX export başarısız.")
        exit(1)
    exported[0].rename(onnx_path)
    logger.info(f"✅ ONNX export tamamlandı: {onnx_path}")
else:
    logger.info("⏩ model.onnx zaten mevcut, yeniden oluşturulmadı.")

# .onnx → .engine
builder = trt.Builder(TRT_LOGGER)
network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
parser = trt.OnnxParser(network, TRT_LOGGER)
config = builder.create_builder_config()

config.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 30)
if builder.platform_has_fast_fp16:
    config.set_flag(trt.BuilderFlag.FP16)
    logger.info("⚡ FP16 desteği etkin")

with open(onnx_path, "rb") as f:
    parsed = parser.parse(f.read())
    if not parsed:
        logger.error("🧨 ONNX parse hatası:")
        for i in range(parser.num_errors):
            logger.error(f"  ↪ {parser.get_error(i)}")
        exit(1)

input_name = network.get_input(0).name
logger.info(f"📌 ONNX giriş tensor ismi: {input_name}")
profile = builder.create_optimization_profile()
profile.set_shape(input_name, (1, 3, 1280, 1280), (1, 3, 1280, 1280), (1, 3, 1280, 1280))
config.add_optimization_profile(profile)

logger.info("🔨 TensorRT engine oluşturuluyor...")
engine_data = builder.build_serialized_network(network, config)
if not engine_data:
    logger.error("🚫 TensorRT engine oluşturulamadı.")
    exit(1)

with open(engine_path, "wb") as f:
    f.write(engine_data)
logger.info(f"✅ TensorRT engine kaydedildi: {engine_path}")
