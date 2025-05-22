from kafka import KafkaConsumer, KafkaProducer
from config import Config
import json


class KafkaManager:
    def __init__(self):
        self.config=Config
        
    def get_consumer(self):
        return KafkaConsumer(
            self.config.INPUT_TOPIC,
            bootstrap_servers=self.config.KAFKA_BOOTSTRAP,
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            max_poll_records=32,
            group_id='ai-unit-group',  
            auto_offset_reset='earliest',
            api_version=(2, 5, 0)
        )
    
    def get_producer(self):
        """Kafka producer oluşturur"""
        return KafkaProducer(
            bootstrap_servers=self.config.KAFKA_BOOTSTRAP,
            value_serializer=lambda x: json.dumps(x).encode('utf-8'),
            api_version=(2, 5, 0))