import flask
from loguru import logger
from flask import request
from TelegramBot import TelegramBot
from utils import Utils

app = flask.Flask(__name__)

TELEGRAM_TOKEN = Utils.get_secret('MX_TELEGRAM_BOT_TOKEN')
TELEGRAM_APP_URL = 'magru.int-devops.click'

logger.info(TELEGRAM_TOKEN)


@app.route('/', methods=['GET'])
def index():
    logger.info('Hello i am from 2.0.6')
    return 'Ok'


@app.route(f'/{TELEGRAM_TOKEN}/', methods=['POST'])
def webhook():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


@app.route(f'/results', methods=['POST'])
def results():
    prediction_id = request.args.get('predictionId')

    # TODO use the prediction_id to retrieve results from DynamoDB and send to the end-user

    chat_id = ...
    text_results = ...

    bot.send_text(chat_id, text_results)
    return 'Ok'


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = TelegramBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL)
    app.run(host='0.0.0.0', port=8443)
