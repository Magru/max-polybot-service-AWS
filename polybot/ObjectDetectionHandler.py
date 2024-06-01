from loguru import logger



class ObjectDetectionHandler:
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
