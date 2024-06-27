import os

import boto3
from loguru import logger
from botocore.exceptions import ClientError
import json


class ResultsHandler:
    def __init__(self, predict_id):
        self.predict_id = predict_id
        self.result = None
        self.dynamodb = boto3.client('dynamodb', 'eu-west-2')
        self.table_name = os.environ['DYNAMODB_TABLE_NAME']
        self.chat_id = None

    def fetch_result(self):
        logger.info(self.predict_id)
        try:
            response = self.dynamodb.get_item(
                TableName='max-aws-project-db',
                Key={
                    'prediction_id': {
                        'S': self.predict_id
                    }
                }
            )
            item = response.get('Item')
            logger.info(item)
            if item:
                try:
                    self.chat_id = item.get('chat_id', {}).get('S')
                except Exception as e:
                    logger.error(f"Error extracting chat_id: {str(e)}")
                    self.result = {
                        'status': 'error',
                        'error': f"Error extracting chat_id: {str(e)}"
                    }
                    return self.result

                labels = self.extract_labels(item)
                beautified_data = self.beautify_data(labels)
                self.result = {
                    'status': 'success',
                    'error': None,
                    'beautified_data': beautified_data
                }
            else:
                self.result = {
                    'status': 'not_found',
                    'error': 'Item not found'
                }

        except ClientError as e:
            self.result = {
                'status': 'error',
                'error': f"ClientError: {e.response['Error']['Message']}"
            }
        except Exception as e:
            self.result = {
                'status': 'error',
                'error': f"Unexpected error: {str(e)}"
            }

        return self.result

    @staticmethod
    def extract_labels(item):
        labels_list = item.get('labels', {}).get('L', [])
        labels_count = {}
        for label in labels_list:
            class_name = label.get('M', {}).get('class', {}).get('S')
            if class_name:
                if class_name in labels_count:
                    labels_count[class_name] += 1
                else:
                    labels_count[class_name] = 1
        return labels_count

    @staticmethod
    def beautify_data(data):
        with open('emoji_map.json', 'r') as file:
            emoji_map = json.load(file)

        default_emoji = '❓'

        output = "Object Count:\n"
        for item, count in data.items():
            emoji = emoji_map.get(item, default_emoji)
            output += f"{emoji} {item.capitalize()}: {count}\n"

        return output
