import os
import json
from kafka import KafkaProducer
from time import sleep
import logging

def create_producer(retries=5, delay=2):
    """
    Kafka producer oluşturur. Belirtilen sayıda deneme yapar.
    
    :param retries: Kafka bağlantısı için deneme sayısı
    :param delay: Denemeler arası bekleme süresi (saniye)
    :return: KafkaProducer nesnesi veya None
    """
    kafka_servers = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")

    for attempt in range(1, retries + 1):
        try:
            producer = KafkaProducer(
                bootstrap_servers=kafka_servers,
                value_serializer=lambda v: json.dumps(v).encode('utf-8')
            )
            print(f"✅ Kafka producer bağlantısı başarılı (deneme {attempt})")
            return producer
        except Exception as e:
            print(f"⚠️ Kafka bağlantısı başarısız (deneme {attempt}): {e}")
            sleep(delay)
    
    print("❌ Kafka producer oluşturulamadı.")
    return None

import os
import json
from kafka import KafkaConsumer

def create_consumer(topic, group_id="frame-splitter", auto_offset_reset="earliest"):
    """
    Kafka topic'ten mesajları almak için consumer oluşturur.
    
    :param topic: Dinlenecek Kafka topic adı
    :param group_id: Consumer group ID
    :param auto_offset_reset: 'earliest' veya 'latest'
    :return: KafkaConsumer nesnesi
    """
    kafka_servers = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
    
    return KafkaConsumer(
        topic,
        bootstrap_servers=kafka_servers,
        group_id=group_id,
        value_deserializer=lambda x: json.loads(x.decode('utf-8')),
        auto_offset_reset=auto_offset_reset,
        enable_auto_commit=True
    )

