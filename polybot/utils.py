import os
import uuid
from loguru import logger
import boto3
from botocore.exceptions import ClientError


def upload_image_file_to_s3(file_name, object_name, add_unique=False):
    s3_bucket_name = os.environ['BUCKET_NAME']
    s3_client = boto3.client('s3')

    if add_unique:
        unique_id = str(uuid.uuid4())
        name, extension = os.path.splitext(object_name)
        object_name = f"{name}_{unique_id}{extension}"

    try:
        s3_client.upload_file(file_name, s3_bucket_name, object_name)
    except ClientError as e:
        logger.error(f'Error on uploading to bucket: {e}.')
        return False
    return object_name
