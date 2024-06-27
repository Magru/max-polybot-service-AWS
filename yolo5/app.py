import time
import uuid
from decimal import Decimal
from pathlib import Path
from detect import run
import yaml
import json
from loguru import logger
import os
import boto3
from AWS import AWS
import requests

images_bucket = os.environ['BUCKET_NAME']
queue_name = os.environ['SQS_QUEUE_NAME']

sqs_client = boto3.client('sqs', region_name='eu-west-2')

with open("data/coco128.yaml", "r") as stream:
    names = yaml.safe_load(stream)['names']


def convert_to_dynamodb_format(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: convert_to_dynamodb_format(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_to_dynamodb_format(v) for v in obj]
    else:
        return obj


def send_post_request(prediction_id):
    url = "https://magru.int-devops.click/results"
    params = {"predictionId": prediction_id}
    try:
        response = requests.post(url, params=params)
        response.raise_for_status()
        logger.info(f"POST request sent successfully for prediction_id: {prediction_id}")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error sending POST request: {e}")


def consume():
    sqs = AWS('sqs')
    s3 = AWS('s3')
    db = AWS('dynamodb')

    while True:
        message = sqs.receive_message(queue_name)
        response_status = 'not_ready'

        if message["status"] == "success":
            sqs_query = json.loads(message["message"])
            prediction_id = str(uuid.uuid4())

            res = s3.download_file(images_bucket, sqs_query["image_id"], f'images/{sqs_query["image_id"]}')

            if res["status"] == "success":
                original_img_path = res["file_path"]
                dir_name, file_name = os.path.split(original_img_path)

                run(
                    weights='yolov5s.pt',
                    data='data/coco128.yaml',
                    source=original_img_path,
                    project='static/data',
                    name=prediction_id,
                    save_txt=True
                )

                predicted_img_path = Path(f'static/data/{prediction_id}/{file_name}')
                pred_summary_path = Path(f'static/data/{prediction_id}/labels/{file_name.split(".")[0]}.txt')

                if pred_summary_path.exists():
                    with open(pred_summary_path) as f:
                        labels = f.read().splitlines()
                        labels = [line.split(' ') for line in labels]
                        labels = [{
                            'class': names[int(l[0])],
                            'cx': float(l[1]),
                            'cy': float(l[2]),
                            'width': float(l[3]),
                            'height': float(l[4]),
                        } for l in labels]

                    object_key = f'predicted_images/{prediction_id}_{file_name}'
                    upload_res = s3.upload_file(images_bucket, predicted_img_path, object_key)

                    if upload_res["status"] == "success":
                        converted_labels = json.loads(json.dumps(labels), parse_float=Decimal)

                        prediction_response = {
                            'prediction_id': prediction_id,
                            'predicted_img_path': str(object_key),
                            'labels': converted_labels,
                            'chat_id': sqs_query["chat_id"]
                        }

                        dynamodb_item = convert_to_dynamodb_format(prediction_response)

                        db_res = db.write_to_dynamodb('max-aws-project-db', dynamodb_item)
                        if db_res["status"] == "success":
                            sqs_res = sqs.delete_message(queue_name, message["receipt_handle"])
                            response_status = 'ready'
                            logger.info(f'S3: {upload_res} DynamoDB: {db_res} SQS: {sqs_res}')

                        if response_status == 'ready':
                            send_post_request(prediction_id)


if __name__ == "__main__":
    consume()
