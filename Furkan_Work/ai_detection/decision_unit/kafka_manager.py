from kafka import KafkaConsumer
from config import Config

class KafkaManager:
    def __init__(self):
        self.bootstrap_servers = Config.KAFKA_BOOTSTRAP

    def get_consumer(self, topic):
        return KafkaConsumer(
            topic,
            bootstrap_servers=self.bootstrap_servers,
            group_id="decision_unit_group",
            auto_offset_reset='earliest',
            enable_auto_commit=True,
            value_deserializer=lambda m: m.decode("utf-8")
        )
