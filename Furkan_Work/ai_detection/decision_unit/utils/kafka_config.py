from kafka import KafkaProducer
import json
import os

def get_segment_kafka_producer():
    kafka_bootstrap = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
    return KafkaProducer(
        bootstrap_servers=kafka_bootstrap,
        value_serializer=lambda v: json.dumps(v).encode("utf-8")
    )
