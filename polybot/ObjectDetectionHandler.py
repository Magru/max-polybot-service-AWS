import boto3
import os
import uuid
from loguru import logger
from botocore.exceptions import ClientError


class ObjectDetectionHandler:

    def __init__(self, image):
        self.image_path = image

    def upload_image_file_to_s3(self, object_name, add_unique=False):
        s3_bucket_name = os.environ['BUCKET_NAME']
        s3_client = boto3.client('s3')

        if add_unique:
            unique_id = str(uuid.uuid4())
            name, extension = os.path.splitext(object_name)
            object_name = f"{name}_{unique_id}{extension}"

        try:
            s3_client.upload_file(self.image_path, s3_bucket_name, object_name)
        except ClientError as e:
            logger.error(f'Error on uploading to bucket: {e}.')
            return False
        return object_name

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
