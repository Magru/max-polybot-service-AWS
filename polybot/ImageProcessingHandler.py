import random
import os
import shutil
from loguru import logger
from Image import Image
from pathlib import Path


class ImageProcessingBot:
    def __init__(self, msg, image_path):
        self.actions = ['blur', 'contour', 'rotate', 'salt_n_pepper', 'segment']
        self.data = msg
        self.image_path = image_path
        self.filtered_image_path = None

        if not self.data.get('caption'):
            raise Exception("caption_not_defined_message")
        elif self.validate_action(self.data.get('caption').lower()):
            self.handle_action(self.data.get('caption').lower())
        else:
            raise Exception("action_not_valid_message")

    def validate_action(self, action):
        return action in self.actions

    def handle_action(self, action):
        if action == 'concat':
            self.handle_concat_action(self.data)
        else:
            self.handle_single_image_action(action)

    @staticmethod
    def handle_concat_action(msg):
        media_group_file = open('photos/' + msg['media_group_id'], 'w')
        media_group_file.close()

    def handle_single_image_action(self, action):
        img = Image(self.image_path)

        try:
            img.handle_filter(action)
            self.filtered_image_path = img.save_img()
        except Exception as err:
            logger.info(err)
            raise Exception(err)

    def get_filtered_image_path(self):
        if self.filtered_image_path is None:
            raise Exception("Filtered image path is not set.")

        return self.filtered_image_path

    @staticmethod
    def clear_photos_folder(photos_path='photos'):
        try:
            if os.path.exists(photos_path):
                for filename in os.listdir(photos_path):
                    file_path = os.path.join(photos_path, filename)
                    try:
                        if os.path.isfile(file_path) or os.path.islink(file_path):
                            os.unlink(file_path)
                        elif os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                    except Exception as e:
                        logger.error(f'Failed to delete {file_path}. Reason: {e}')
                logger.info(f"All files in '{photos_path}' folder have been cleared.")
            else:
                logger.error(f"'{photos_path}' folder does not exist.")
        except Exception as e:
            logger.error(f"Error: {e}")

    def clean_images(self):
        original_image = Path(self.image_path)
        filtered_image = Path(self.filtered_image_path)

        if original_image.exists():
            original_image.unlink()
            logger.info(f"Removed original image: {original_image}")
        else:
            logger.info(f"Original image file does not exist: {original_image}")

        if filtered_image.exists():
            filtered_image.unlink()
            logger.info(f"Removed filtered image: {filtered_image}")
        else:
            logger.info(f"Filtered image file does not exist: {filtered_image}")
