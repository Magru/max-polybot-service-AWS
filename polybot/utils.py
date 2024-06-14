import os
import uuid
import json
from loguru import logger
import boto3
from botocore.exceptions import ClientError


class Utils:
    class UtilsException(Exception):
        pass

    @staticmethod
    def upload_image_file_to_s3(file_name, object_name, add_unique=False):
        """Uploads an image file to an S3 bucket."""
        s3_bucket_name = os.getenv('BUCKET_NAME')
        if not s3_bucket_name:
            logger.error("Environment variable 'BUCKET_NAME' not set.")
            raise Utils.UtilsException("Environment variable 'BUCKET_NAME' not set.")

        s3_client = boto3.client('s3')

        if add_unique:
            object_name = Utils._add_unique_identifier(object_name)

        try:
            s3_client.upload_file(file_name, s3_bucket_name, object_name)
            return object_name
        except ClientError as e:
            logger.error(f'Error uploading to bucket: {e}.')
            return False

    @staticmethod
    def _add_unique_identifier(object_name):
        """Adds a unique identifier to the object name."""
        unique_id = str(uuid.uuid4())
        name, extension = os.path.splitext(object_name)
        return f"{name}_{unique_id}{extension}"

    @staticmethod
    def get_secret(name, secret_name="max-telegram", region_name="eu-west-2"):
        """Retrieves a secret value by name from AWS Secrets Manager."""
        client = Utils._create_secrets_manager_client(region_name)

        secret_string = Utils._get_secret_string(client, secret_name)

        secret = Utils._parse_secret_string(secret_string)

        if name not in secret:
            error_message = f"The name '{name}' does not exist in the secret."
            logger.error(error_message)
            raise KeyError(error_message)

        return secret[name]

    @staticmethod
    def _create_secrets_manager_client(region_name):
        """Create a Secrets Manager client."""
        session = boto3.session.Session()
        return session.client(service_name='secretsmanager', region_name=region_name)

    @staticmethod
    def _get_secret_string(client, secret_name):
        """Retrieve the secret string from AWS Secrets Manager."""
        try:
            get_secret_value_response = client.get_secret_value(SecretId=secret_name)
            return get_secret_value_response.get('SecretString')
        except ClientError as e:
            logger.error(f"Failed to retrieve secret: {e}")
            raise Utils.UtilsException(f"Failed to retrieve secret: {e}")

    @staticmethod
    def _parse_secret_string(secret_string):
        """Parse the secret string into a dictionary."""
        try:
            return json.loads(secret_string)
        except (json.JSONDecodeError, TypeError) as e:
            logger.error(f"Error decoding secret: {e}")
            raise Utils.UtilsException(f"Error decoding secret: {e}")
