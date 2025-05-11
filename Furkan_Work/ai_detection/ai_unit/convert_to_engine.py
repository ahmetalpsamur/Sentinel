import tensorrt as trt
import os

TRT_LOGGER = trt.Logger(trt.Logger.WARNING)

def build_engine(onnx_path, engine_path):
    builder = trt.Builder(TRT_LOGGER)
    network_flags = (1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
    network = builder.create_network(network_flags)
    parser = trt.OnnxParser(network, TRT_LOGGER)
    config = builder.create_builder_config()

    # Yeni API: Workspace boyutu belirleme (TensorRT 8.6+)
    if hasattr(config, "set_memory_pool_limit"):
        config.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 30)  # 1GB

    with open(onnx_path, 'rb') as model:
        if not parser.parse(model.read()):
            print("[❌] ONNX parse hatası:")
            for i in range(parser.num_errors):
                print(parser.get_error(i))
            return

    # Yeni API: build_engine yerine build_serialized_network
    serialized_engine = builder.build_serialized_network(network, config)

    if serialized_engine is None:
        print("[❌] Engine oluşturulamadı.")
        return

    with open(engine_path, "wb") as f:
        f.write(serialized_engine)
    print(f"[✅] Engine dosyası oluşturuldu: {engine_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    model_dir = os.path.join(base_dir, "models")

    onnx_path = os.path.join(model_dir, "model.onnx")
    engine_path = os.path.join(model_dir, "model.engine")

    build_engine(onnx_path, engine_path)
