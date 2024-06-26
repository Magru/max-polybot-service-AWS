import boto3
from loguru import logger
from botocore.exceptions import ClientError


class ResultsHandler:
    def __init__(self, predict_id):
        self.predict_id = predict_id
        self.result = None
        self.dynamodb = boto3.resource('dynamodb', 'eu-west-2')
        self.table = self.dynamodb.Table('max-aws-project-db')

    def fetch_result(self):
        try:
            response = self.table.get_item(
                Key={
                    'predict_id': self.predict_id
                }
            )
            item = response.get('Item')
            logger.info(response)

            if item:
                self.result = item  # Store the result
                return {
                    'status': 'success',
                    'error': None
                }
            else:
                return {
                    'status': 'not_found',
                    'error': 'Item not found'
                }

        except ClientError as e:
            return {
                'status': 'error',
                'error': f"ClientError: {e.response['Error']['Message']}"
            }
        except Exception as e:
            return {
                'status': 'error',
                'error': f"Unexpected error: {str(e)}"
            }
