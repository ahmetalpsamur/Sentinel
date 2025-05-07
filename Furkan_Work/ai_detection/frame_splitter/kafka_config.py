import os
import json
from kafka import KafkaConsumer

KAFKA_SERVERS = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")

def create_consumer(topic):
    return KafkaConsumer(
        topic,
        bootstrap_servers=KAFKA_SERVERS,
        value_deserializer=lambda x: json.loads(x.decode('utf-8')),
        auto_offset_reset='earliest',
        group_id='frame-splitter'
    )
