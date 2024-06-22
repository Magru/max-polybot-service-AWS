import boto3
import os
import uuid
import json
from loguru import logger
from botocore.exceptions import ClientError
from utils import Utils


class ObjectDetectionHandler:

    def __init__(self, image, chat_id):
        self.image_path = image
        self.uploaded_object = None
        self.chat_id = chat_id

    def run(self):
        upload_res = self.upload_image_file_to_s3()
        logger.info(upload_res)
        que_res = self.send_message_to_sqs(upload_res["object_name"])
        logger.info(que_res)

    def upload_image_file_to_s3(self):
        s3_bucket_name = os.environ['IMAGES_BUCKET_NAME']
        s3_client = boto3.client('s3')

        unique_id = str(uuid.uuid4())
        name, extension = os.path.splitext(self.image_path)
        object_name = f"{unique_id}{extension}"

        try:
            s3_client.upload_file(self.image_path, s3_bucket_name, object_name)
            return {
                "success": True,
                "message": "Image uploaded successfully! 🎉",
                "object_name": object_name
            }
        except ClientError as e:
            error_message = f'Error on uploading to bucket: {e}'
            logger.error(error_message)
            return {
                "success": False,
                "message": "Oops! 😅 We encountered a small hiccup while uploading your image. Our tech gnomes are on "
                           "it! Please try again in a moment. If the issue persists, it might be time for a coffee "
                           "break ☕️"
            }
        except Exception as e:
            error_message = f'Unexpected error on uploading to bucket: {e}'
            logger.error(error_message)
            return {
                "success": False,
                "message": "Well, this is embarrassing! 🙈 Something unexpected happened on our end. Don't worry, "
                           "our code monkeys are already swinging into action! Please give it another shot in a few "
                           "minutes."
            }

    def send_message_to_sqs(self, image_id):
        sqs_client = boto3.client('sqs', region_name='eu-west-2')
        sqs_queue_url = 'https://sqs.eu-west-2.amazonaws.com/019273956931/max-aws-project-sqs.fifo'
        logger.info(f'SQS: {sqs_queue_url}')

        try:
            message_body = json.dumps({
                'chat_id': self.chat_id,
                'image_id': image_id
            })
            response = sqs_client.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=message_body,
                MessageGroupId='object_detection',
                MessageDeduplicationId=str(uuid.uuid4())
            )
            logger.info(f'Successfully sent message to SQS: {response["MessageId"]}')
            return True
        except Exception as e:
            logger.error(f'Error sending message to SQS: {e}')
            return False

    def handle_message(self, msg):
        logger.info(f'Incoming message: {msg}')
        # self.send_text(msg['chat']['id'], f'Your original message: {msg["text"]}')
        #
        # if self.is_current_msg_photo(msg):
        #     photo_path = self.download_user_photo(msg)
        #
        #     # TODO upload the photo to S3
        #     # TODO send a job to the SQS queue
        #     # TODO send message to the Telegram end-user (e.g. Your image is being processed. Please wait...)
