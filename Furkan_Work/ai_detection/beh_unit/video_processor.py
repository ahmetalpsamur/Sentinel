import torch
import numpy as np
from decord import VideoReader, cpu
from transformers import VideoMAEForVideoClassification, VideoMAEImageProcessor
from logger import setup_logger
from huggingface_hub import login
import os

logger = setup_logger("video_processor")

hf_token = ""
if hf_token:
    logger.info("🔑 Logging in to HuggingFace Hub with token...")
    login(token=hf_token)
    logger.info("✅ HuggingFace login successful")

labels = [
    "Abuse/Normal", "Arrest", "Arson", "Assault", "Burglary", "Explosion",
    "Fighting", "Normal Videos", "Road Accidents", "Robbery",
    "Shooting", "Shoplifting", "Stealing", "Vandalism"
]

logger.info("🧠 Loading model and processor from HuggingFace...")
processor = VideoMAEImageProcessor.from_pretrained("MCG-NJU/videomae-large")
model = VideoMAEForVideoClassification.from_pretrained(
    "OPear/videomae-large-finetuned-UCF-Crime", ignore_mismatched_sizes=True
)
model.eval()
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)
logger.info("✅ Model loaded and moved to device")

def preprocess_video(path, num_frames=16):
    logger.info(f"🧼 Preprocessing video: {path}")
    vr = VideoReader(path, ctx=cpu(0))
    total = len(vr)
    if total < num_frames:
        raise ValueError(f"Not enough frames: {total}")
    indices = np.linspace(0, total - 1, num_frames, dtype=int)
    frames = vr.get_batch(indices).asnumpy()
    if frames.shape[-1] != 3:
        raise ValueError(f"Frame channel mismatch")
    inputs = processor(list(frames), return_tensors="pt")
    return inputs["pixel_values"]

def classify_video(path):
    try:
        logger.info(f"🧪 Starting classification: {path}")
        tensor = preprocess_video(path).to(device)
        with torch.no_grad():
            outputs = model(pixel_values=tensor)
            probs = torch.nn.functional.softmax(outputs.logits, dim=-1)[0].tolist()

        result_dict = dict(zip(labels, [p * 100 for p in probs])) 
        logger.info(f"✅ Classification complete for {path}")
        return result_dict

    except Exception as e:
        logger.error(f"❌ Failed to classify video: {e}")
        return None

