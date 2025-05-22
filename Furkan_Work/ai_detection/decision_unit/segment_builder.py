import os
import cv2
import base64
import numpy as np
import json
from utils.redis_config import get_redis_client
from utils.video_utils import get_video_metadata
from utils.logger import setup_logger
from config import Config
from utils.db_writer import insert_segment,get_video_resolution,segment_for_ui
import uuid
import subprocess
from collections import Counter
from utils.kafka_config import get_segment_kafka_producer

logger = setup_logger()
redis_client = get_redis_client()
def fourcc(c1, c2, c3, c4):
    return (ord(c1)) + (ord(c2) << 8) + (ord(c3) << 16) + (ord(c4) << 24)

def draw_boxes_with_labels(image, detections, input_shape=(416, 416), original_shape=(416, 416)):
    """Tüm bounding box'ları çizer ve üzerine silah türü ile confidence yazısı ekler"""
    input_h, input_w = input_shape
    original_h, original_w = original_shape

    scale_x = original_w / input_w
    scale_y = original_h / input_h

    for det in detections:
        box = det.get("box", [])
        conf = det.get("confidence", 0.0)
        wtype = det.get("weapon_type", "unknown")

        if not box or len(box) != 4:
            continue

        # Ölçekle
        x1 = int(box[0] * scale_x)
        y1 = int(box[1] * scale_y)
        x2 = int(box[2] * scale_x)
        y2 = int(box[3] * scale_y)

        label = f"{wtype} ({conf:.2f})"

        # Kutu çiz
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)

        # Label arka planı
        (text_w, text_h), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
        cv2.rectangle(image, (x1, y1 - text_h - 5), (x1 + text_w, y1), (0, 255, 0), -1)

        # Label metni
        cv2.putText(
            image, label, (x1, y1 - 5),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1, cv2.LINE_AA
        )

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
def coalesce_segments(segments, max_gap=Config.SEGMENT_MERGE_GAP):
    if not segments:
        return []
    
    # Segmentleri başlangıç zamanına göre sırala
    sorted_segments = sorted(segments, key=lambda x: x[0])
    
    merged = [sorted_segments[0]]
    for current in sorted_segments[1:]:
        last = merged[-1]
        # Ara kontrolü (current.start - last.end <= max_gap)
        if current[0] - last[1] <= max_gap:
            # Segmentleri birleştir
            new_segment = (last[0], current[1])
            merged[-1] = new_segment
        else:
            merged.append(current)
    return merged
def calculate_dynamic_threshold(window_size):
    """Pencere boyutuna göre dinamik eşik hesapla"""
    return max(
        Config.BASE_MIN_DETECTIONS,
        int(window_size * Config.DETECTION_PER_FRAME)
    )
def calculate_segment_quality(frames_in_segment):
    """Segment için kalite skoru hesapla (0-1 arası)"""
    total_frames = len(frames_in_segment)
    detected_frames = sum(1 for f in frames_in_segment if f["is_detected"])
    
    # Basit bir skorlama: tespit edilen frame yüzdesi
    return detected_frames / total_frames if total_frames > 0 else 0


def build_segment_for_video(video_id, frames, window_size=Config.SEGMENT_WINDOW_SIZE, min_detections=Config.SEGMENT_MIN_DETECTIONS):
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
    dynamic_threshold = calculate_dynamic_threshold(window_size)
    flags = counts >= dynamic_threshold

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
    merged_segments = coalesce_segments(segments)
    
    for idx, (start_idx, end_idx) in enumerate(merged_segments):
        padding_frames = int(Config.SEGMENT_PADDING_SECONDS * fps)
        adj_start = max(start_idx - padding_frames, 0)
        adj_end = min(end_idx + padding_frames, total_frames)

        weapon_types = []
        for f in frames:
            if f.get("is_detected") and adj_start <= f["frame_index"] <= adj_end:
                detection_list = f.get("detections", [])
                for det in detection_list:
                    weapon_types.append(det.get("weapon_type", "unknown"))

        most_common_weapon = Counter(weapon_types).most_common(1)
        dominant_weapon = most_common_weapon[0][0] if most_common_weapon else "unknown"

        original_w, original_h = get_video_resolution(video_id)
        input_w, input_h = 416, 416

        logger.info(f"🎬 Segment {idx+1}: frames {adj_start} → {adj_end}")
        frame_metadata = {f["frame_index"]: f for f in frames}

        frame_array = []
        for frame_index in range(adj_start, adj_end):
            frame_id_key = f"frame_index:{frame_index}"
            frame_id = redis_client.get(frame_id_key)
            if not frame_id:
                logger.warning(f"❌ frame_id bulunamadı (index={frame_index})")
                continue
            frame_id = frame_id.decode()

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

            detection_list = frame_metadata.get(frame_index, {}).get("detections", [])
            if detection_list:
                img = draw_boxes_with_labels(
                    image=img,
                    detections=detection_list,
                    input_shape=(input_h, input_w),
                    original_shape=(original_h, original_w)
                )

            frame_array.append(img)

        if not frame_array:
            logger.warning("Segment için yeterli frame yok.")
            continue

        try:
            height, width, _ = frame_array[0].shape
            segment_dir = os.path.join("data", "segment_videos", video_id)
            os.makedirs(segment_dir, exist_ok=True)

            segment_id = str(uuid.uuid4())
            temp_avi_path = os.path.join(segment_dir, f"{segment_id}.avi")
            output_path = os.path.join(segment_dir, f"{segment_id}.mp4")

            codec = fourcc(*Config.SEGMENT_INPUT_CODEC)
            writer = cv2.VideoWriter(temp_avi_path, codec, fps, (width, height))

            if not writer.isOpened():
                logger.error(f"❌ VideoWriter açılamadı! Yol: {temp_avi_path}")
                continue

            for frame in frame_array:
                writer.write(frame)
            writer.release()

            try:
                subprocess.run([
                    "ffmpeg", "-y",
                    "-i", temp_avi_path,
                    "-c:v", Config.SEGMENT_OUTPUT_CODEC,
                    "-preset", Config.SEGMENT_FFMPEG_PRESET,
                    "-crf", str(Config.SEGMENT_FFMPEG_CRF),
                    "-movflags", "+faststart",
                    output_path
                ], check=True)
                os.remove(temp_avi_path)
                logger.info(f"✅ Segment video oluşturuldu (H264): {output_path}")
            except Exception as e:
                logger.error(f"❌ FFmpeg ile mp4 dönüştürme hatası: {e}")
                continue

        except Exception as e:
            logger.exception(f"❌ Video yazımı hatası: {e}")
            continue
        quality_score = calculate_segment_quality(frames[adj_start:adj_end])
        logger.info(f"✅ Segment Kalite Skoru: {quality_score:.2%}")
        
        # Kaliteye göarş uyarı
        if quality_score < 0.2:
            logger.warning("⚠️ Düşük Kaliteli Segment! Manuel Kontrol Önerilir.")

        segment_metadata = {
            "segment_id": segment_id,
            "video_id": video_id,
            "start_frame": int(adj_start),
            "end_frame": int(adj_end),
            "start_time": round(adj_start / fps, 2),
            "end_time": round(adj_end / fps, 2),
            "dominant_class": "unknown",
            "score": round(np.mean([
                det.get("confidence", 0.0)
                for f in frames if f["is_detected"]
                for det in f.get("detections", [])
                if adj_start <= f["frame_index"] <= adj_end
            ]), 4),
            "total_frames": int(adj_end - adj_start),
            "positive_frames": int(sum(binary_array[adj_start:adj_end])),
            "bounding_boxes": json.dumps([
                {
                    "frame_index": f["frame_index"],
                    "detections": f["detections"]
                }
                for f in frames if f["is_detected"] and adj_start <= f["frame_index"] <= adj_end
            ]),
            "output_path": output_path
        }

        segment_data = {
            "segment_id": segment_id,
            "weapon_score": segment_metadata["score"],
            "weapon_type": dominant_weapon,
            "url": f"http://{Config.BACKEND_HOST}:{Config.BACKEND_PORT}/stream/{segment_id}",
            "description": "",
            "crime_type": ""
        }

        insert_segment(segment_metadata)
        logger.info(f"Segment kaydedildi. Segment id:{segment_id}, uzunluk:{round((adj_end - adj_start) / fps, 2)}")

        segment_for_ui(segment_data)
        logger.info(f"Segment UI kaydedildi. Segment id:{segment_id}")

        producer = get_segment_kafka_producer()
        kafka_msg = {
            "segment_id": segment_id,
            "path": output_path
        }
        try:
            producer.send(Config.OUTPUT_TOPUC, kafka_msg)
            producer.flush()
            logger.info(f"📤 Kafka'ya gönderildi: segment_id={segment_id}")
        except Exception as e:
            logger.error(f"❌ Kafka gönderimi başarısız: {e}")