import flask
from loguru import logger
from flask import request
from TelegramBot import TelegramBot
from utils import Utils
from ResultsHandler import ResultsHandler

app = flask.Flask(__name__)

TELEGRAM_TOKEN = Utils.get_secret('MX_TELEGRAM_BOT_TOKEN')
TELEGRAM_APP_URL = 'magru.int-devops.click'


@app.route('/', methods=['GET'])
def index():
    return 'Ok'


@app.route(f'/{TELEGRAM_TOKEN}/', methods=['POST'])
def webhook():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


@app.route(f'/results', methods=['POST'])
def results():
    prediction_id = request.args.get('predictionId')
    result_handler = ResultsHandler(prediction_id)
    fetch_res = result_handler.fetch_result()
    logger.info(fetch_res)
    logger.info(result_handler.result)

    # chat_id = ...
    # text_results = ...

    #bot.send_text(chat_id, text_results)
    return result_handler.result


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = TelegramBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL)
    app.run(host='0.0.0.0', port=8443)
