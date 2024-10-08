import flask
from loguru import logger
from flask import request
from TelegramBot import TelegramBot
from utils import Utils
from ResultsHandler import ResultsHandler

app = flask.Flask(__name__)

TELEGRAM_TOKEN = Utils.get_secret('MX_TELEGRAM_BOT_TOKEN')
TELEGRAM_APP_URL = Utils.get_secret('MX_TELEGRAM_BOT_URL')


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
    result_handler.fetch_result()
    logger.info(result_handler)
    if result_handler.result["status"] == "success":
        if result_handler.result["predicted_image_path"]["result"] == "success":
            bot.send_photo(result_handler.chat_id,
                           result_handler.result["predicted_image_path"]["path"],
                           result_handler.result["beautified_data"])
        else:
            bot.send_text(result_handler.chat_id, result_handler.result["beautified_data"])

        result_handler.clean_up()

    return "Ok"


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = TelegramBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL)
    app.run(host='0.0.0.0', port=8443)
