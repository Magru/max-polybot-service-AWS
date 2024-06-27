import boto3
from loguru import logger
from botocore.exceptions import ClientError


class ResultsHandler:
    def __init__(self, predict_id):
        self.predict_id = predict_id
        self.result = None
        self.dynamodb = boto3.client('dynamodb', 'eu-west-2')

    def fetch_result(self):
        logger.info(self.predict_id)
        try:
            response = self.dynamodb.get_item(
                TableName='max-aws-project-db',
                Key={
                    'prediction_id': self.predict_id
                }
            )
            item = response.get('Item')
            logger.info(response)
            logger.info(item)

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
