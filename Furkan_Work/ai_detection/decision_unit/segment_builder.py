import os
import cv2
import base64
import numpy as np
import json
from utils.redis_config import get_redis_client
from utils.video_utils import get_video_metadata
from utils.logger import setup_logger
from config import Config
from utils.db_writer import insert_segment
import uuid
from utils.db_writer import get_video_resolution 

logger = setup_logger()
redis_client = get_redis_client()
def fourcc(c1, c2, c3, c4):
    return (ord(c1)) + (ord(c2) << 8) + (ord(c3) << 16) + (ord(c4) << 24)

def draw_boxes(image, boxes):
    """Tespit edilen kutuları çizer"""
    for box in boxes:
        x1, y1, x2, y2 = map(int, box)
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
    return image
def rescale_boxes(boxes, input_shape, original_shape):
    ih, iw = input_shape
    oh, ow = original_shape

    scale_x = ow / iw
    scale_y = oh / ih

    return [[
        int(x1 * scale_x), int(y1 * scale_y),
        int(x2 * scale_x), int(y2 * scale_y)
    ] for x1, y1, x2, y2 in boxes]


def build_segment_for_video(video_id, frames, window_size=30, min_detections=10):
    logger.info(f"🔧 Building segment for video: {video_id}")

    # 1. Video metadata çek
    metadata = get_video_metadata(video_id)
    if not metadata:
        logger.error(f"Metadata bulunamadı: {video_id}")
        return

    fps = metadata['fps']
    total_frames = metadata['total_frames']

    # 2. Binary dizi oluştur (frame index'e göre)
    binary_array = np.zeros(total_frames, dtype=int)
    for f in frames:
        if f["is_detected"]:
            binary_array[f["frame_index"]] = 1

    # 3. Sliding window yoğunluk hesabı
    counts = np.convolve(binary_array, np.ones(window_size, dtype=int), mode='valid')
    flags = counts >= min_detections

    segments = []
    in_segment = False
    for i, flag in enumerate(flags):
        if flag and not in_segment:
            start = i
            in_segment = True
        elif not flag and in_segment:
            end = i + window_size
            segments.append((start, end))
            in_segment = False
    if in_segment:
        segments.append((start, total_frames))

    if not segments:
        logger.info(f"⚠️ Yoğunluk eşiği karşılanmadı: {video_id}")
        return

    # 4. Her segment için Redis’ten frame çek ve video yaz
    for idx, (start_idx, end_idx) in enumerate(segments):
        adj_start = max(start_idx - int(2 * fps), 0)
        adj_end = min(end_idx + int(2 * fps), total_frames)
        original_w, original_h = get_video_resolution(video_id)
        input_w, input_h = 416, 416  

        logger.info(f"🎬 Segment {idx+1}: frames {adj_start} → {adj_end}")
        frame_metadata = {f["frame_index"]: f for f in frames}

        frame_array = []
        for frame_index in range(adj_start, adj_end):
            # 1. frame_index -> frame_id
            frame_id_key = f"frame_index:{frame_index}"
            frame_id = redis_client.get(frame_id_key)
            if not frame_id:
                logger.warning(f"❌ frame_id bulunamadı (index={frame_index})")
                continue
            frame_id = frame_id.decode()

            # 2. frame_id -> frame_data
            redis_key = f"frame:{frame_id}"
            redis_data = redis_client.get(redis_key)
            if not redis_data:
                logger.warning(f"❌ Redis'te veri yok: {redis_key}")
                continue

            decoded = json.loads(redis_data)
            base64_img = decoded.get("original_data")
            if not base64_img:
                logger.warning(f"❌ Görsel verisi yok: {frame_id}")
                continue

            img_bytes = base64.b64decode(base64_img)
            np_arr = np.frombuffer(img_bytes, np.uint8)
            img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if img is None:
                logger.warning(f"⚠️ Görsel decode edilemedi: {frame_id}")
                continue
            bounding_box = frame_metadata.get(frame_index, {}).get("bounding_boxes", [])

            if bounding_box and original_w and original_h:
                resized_boxes = rescale_boxes(bounding_box, (input_h, input_w), (original_h, original_w))
                img = draw_boxes(img, resized_boxes)

            frame_array.append(img)

        if not frame_array:
            logger.warning("Segment için yeterli frame yok.")
            continue

        # 4. Segment video kaydet
        try:
            height, width, _ = frame_array[0].shape
            segment_dir = os.path.join("data", "segment_videos", video_id)
            os.makedirs(segment_dir, exist_ok=True)

            segment_id = str(uuid.uuid4())
            output_path = os.path.join(segment_dir, f"segment_{idx+1}.mp4")

            codec = fourcc('m', 'p', '4', 'v')
            writer = cv2.VideoWriter(output_path, codec, fps, (width, height))

            if not writer.isOpened():
                logger.error(f"❌ VideoWriter açılamadı! Yol: {output_path}")
                continue

            for frame in frame_array:
                writer.write(frame)

            writer.release()

            if os.path.exists(output_path):
                logger.info(f"✅ Segment video oluşturuldu: {output_path}")
            else:
                logger.error(f"❌ Segment dosyası kaydedilemedi: {output_path}")
                continue

        except Exception as e:
            logger.exception(f"❌ Video yazımı hatası: {e}")
            continue


        segment_metadata = {
            "segment_id": segment_id,
            "video_id": video_id,
            "start_frame": int(adj_start),
            "end_frame": int(adj_end),
            "start_time": round(adj_start / fps, 2),
            "end_time": round(adj_end / fps, 2),
            "dominant_class": "unknown",
            "score": round(np.mean([f["confidence"] for f in frames if f["frame_index"] >= adj_start and f["frame_index"] <= adj_end and f["is_detected"]]), 4),
            "total_frames": int(adj_end - adj_start),
            "positive_frames": int(sum(binary_array[adj_start:adj_end])),
            "bounding_boxes": json.dumps([f for f in frames if f["is_detected"] and adj_start <= f["frame_index"] <= adj_end]),
            "output_path": output_path
        }

        insert_segment(segment_metadata)
        logger.info(f"Segment kaydedildi. Segment id:{segment_id}, uzunluk:{round((adj_end-adj_start)/fps,2)}")
