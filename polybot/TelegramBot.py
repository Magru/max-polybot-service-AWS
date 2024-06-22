import telebot
from loguru import logger
import os
import time
import json
from telebot.types import InputFile
from ObjectDetectionHandler import ObjectDetectionHandler
from ImageProcessingHandler import ImageProcessingBot


class TelegramBot:

    def __init__(self, token, telegram_chat_url):
        # create a new instance of the TeleBot class.
        # all communication with Telegram servers are done using self.telegram_bot_client
        self.telegram_bot_client = telebot.TeleBot(token)

        # remove any existing webhooks configured in Telegram servers
        self.telegram_bot_client.remove_webhook()
        time.sleep(0.5)

        # set the webhook URL
        self.telegram_bot_client.set_webhook(url=f'{telegram_chat_url}/{token}/', timeout=60)

        with open('messages.json') as f:
            self.messages = json.load(f)

        logger.info(f'Telegram Bot information\n\n{self.telegram_bot_client.get_me()}')

    def send_text(self, chat_id, text):
        self.telegram_bot_client.send_message(chat_id, text)

    def send_text_with_quote(self, chat_id, text, quoted_msg_id):
        self.telegram_bot_client.send_message(chat_id, text, reply_to_message_id=quoted_msg_id)

    @staticmethod
    def is_current_msg_photo(msg):
        return 'photo' in msg

    def download_user_photo(self, msg):
        """
        Downloads the photos that sent to the Bot to `photos` directory (should be existed)
        :return:
        """
        if not self.is_current_msg_photo(msg):
            raise RuntimeError(f'Message content of type \'photo\' expected')

        file_info = self.telegram_bot_client.get_file(msg['photo'][-1]['file_id'])
        data = self.telegram_bot_client.download_file(file_info.file_path)
        folder_name = file_info.file_path.split('/')[0]

        if not os.path.exists(folder_name):
            os.makedirs(folder_name)

        with open(file_info.file_path, 'wb') as photo:
            photo.write(data)

        return file_info.file_path

    def send_photo(self, chat_id, img_path):
        if not os.path.exists(img_path):
            raise RuntimeError("Image path doesn't exist")

        self.telegram_bot_client.send_photo(
            chat_id,
            InputFile(img_path)
        )

    def text_response_handler(self, command, chat_id):
        """
        Handles commands sent to the Telegram bot with the inclusion of chat ID.

        Args:
        - command (str): The command sent to the bot.
        - chat_id (int): The unique identifier for the chat.

        Returns:
        - str: The response message.
        """
        message = self.messages.get(command.lstrip("/"), self.messages['default_response'])
        return message.format(chat_id=chat_id)

    def handle_message(self, msg):
        """Bot Main message handler"""
        logger.info(f'Incoming message: {msg}')
        chat_id = msg['chat']['id']

        if self.is_current_msg_photo(msg):
            image = self.download_user_photo(msg)
            caption = msg.get('caption')
            logger.info(caption)
            self.send_text(chat_id, f'Caption id ${caption}')
            try:
                if caption and caption.lower() == 'predict':
                    logger.info('inside if')
                    object_detection = ObjectDetectionHandler(image)
                else:
                    img_proc = ImageProcessingBot(msg, image)
                    response_image = img_proc.get_filtered_image_path()
                    self.send_photo(chat_id, response_image)
                    img_proc.clean_images()
            except Exception as e:
                self.send_text(chat_id, self.text_response_handler(str(e), chat_id))

        else:
            self.send_text(chat_id, self.text_response_handler(msg['text'], chat_id))


