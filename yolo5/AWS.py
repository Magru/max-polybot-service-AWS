import boto3
from loguru import logger
from botocore.exceptions import BotoCoreError, ClientError


class AWS:
    def __init__(self, service_name, region_name='eu-west-2'):
        self.service_name = service_name
        self.region_name = region_name
        self.client = self.create_client()

    def create_client(self):
        if self.service_name in ['sqs', 's3', 'dynamodb']:
            return boto3.client(self.service_name, region_name=self.region_name)
        else:
            raise ValueError(f"Unsupported service: {self.service_name}")

    def receive_message(self, queue_name):
        if self.service_name != 'sqs':
            return {"status": "error", "message": "Client is not initialized for SQS service"}

        try:
            response = self.client.receive_message(QueueUrl=queue_name, MaxNumberOfMessages=1, WaitTimeSeconds=5)
            if 'Messages' in response:
                message = response['Messages'][0]['Body']
                receipt_handle = response['Messages'][0]['ReceiptHandle']
                return {"status": "success", "message": message, "receipt_handle": receipt_handle}
            else:
                return {"status": "error", "message": "No messages available"}
        except self.client.exceptions.QueueDoesNotExist:
            return {"status": "error", "message": f"Queue {queue_name} does not exist"}
        except (BotoCoreError, ClientError) as error:
            return {"status": "error", "message": f"An error occurred: {error}"}

    def download_file(self, bucket_name, object_key, file_name):
        if self.service_name != 's3':
            return {"status": "error", "message": "Client is not initialized for S3 service"}

        try:
            self.client.download_file(bucket_name, object_key, file_name)
            return {"status": "success", "file_path": file_name}
        except self.client.exceptions.NoSuchBucket:
            return {"status": "error", "message": f"Bucket {bucket_name} does not exist"}
        except self.client.exceptions.NoSuchKey:
            return {"status": "error", "message": f"Object {object_key} does not exist in bucket {bucket_name}"}
        except (BotoCoreError, ClientError) as error:
            return {"status": "error", "message": f"An error occurred: {error}"}

    def upload_file(self, bucket_name, file_name, object_key):
        if self.service_name != 's3':
            return {"status": "error", "message": "Client is not initialized for S3 service"}

        try:
            self.client.upload_file(file_name, bucket_name, object_key)
            return {"status": "success", "message": f"File {file_name} uploaded to {bucket_name}/{object_key}"}
        except FileNotFoundError:
            return {"status": "error", "message": f"File {file_name} not found"}
        except self.client.exceptions.NoSuchBucket:
            return {"status": "error", "message": f"Bucket {bucket_name} does not exist"}
        except (BotoCoreError, ClientError) as error:
            return {"status": "error", "message": f"An error occurred: {error}"}

    def write_to_dynamodb(self, table_name, item):
        if self.service_name != 'dynamodb':
            return {"status": "error", "message": "Client is not initialized for DynamoDB service"}

        dynamodb = boto3.resource('dynamodb', region_name=self.region_name)
        table = dynamodb.Table(table_name)

        try:
            response = table.put_item(Item=item)
            return {"status": "success", "message": f"Item successfully written to {table_name}", "response": response}
        except self.client.exceptions.ResourceNotFoundException:
            return {"status": "error", "message": f"Table {table_name} does not exist"}
        except self.client.exceptions.ProvisionedThroughputExceededException:
            return {"status": "error", "message": "Provisioned throughput exceeded"}
        except self.client.exceptions.ConditionalCheckFailedException:
            return {"status": "error", "message": "Conditional check failed"}
        except (BotoCoreError, ClientError) as error:
            return {"status": "error", "message": f"An error occurred: {str(error)}"}

    def delete_message(self, queue_url, receipt_handle):
        if self.service_name != 'sqs':
            return {"status": "error", "message": "Client is not initialized for SQS service"}

        try:
            response = self.client.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=receipt_handle
            )
            return {"status": "success", "message": "Message deleted successfully", "response": response}
        except self.client.exceptions.InvalidReceiptHandle:
            return {"status": "error", "message": "Invalid receipt handle"}
        except self.client.exceptions.QueueDoesNotExist:
            return {"status": "error", "message": f"Queue {queue_url} does not exist"}
        except (BotoCoreError, ClientError) as error:
            return {"status": "error", "message": f"An error occurred: {error}"}