import csv
import json
import time
from datetime import datetime
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers=['34.6.80.191:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

with open('aac_intakes.csv', mode='r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    for row in reader:
        event = {
            "animal_id": row["animal_id"],
            "animal_type": row["animal_type"],
            "intake_type": row["intake_type"],
            "intake_condition": row["intake_condition"],
            "event_time": datetime.now().isoformat()  # Current timestamp for live windowing
        }
        producer.send('shelter-intakes', value=event)
        print(f"Sent: {event['animal_id']} ({event['animal_type']})")
        time.sleep(0.5)  # Simulate 2 intakes per second

producer.flush()