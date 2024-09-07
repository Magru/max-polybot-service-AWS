FROM ultralytics/yolov5:v6.2-cpu
WORKDIR /usr/src/app
ENV BUCKET_NAME=max-yolo5
ENV SQS_QUEUE_NAME=https://sqs.eu-west-2.amazonaws.com/019273956931/max-terraform-project-sqs.fifo
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN curl -L https://github.com/ultralytics/yolov5/releases/download/v6.1/yolov5s.pt -o yolov5s.pt

COPY . .

CMD ["python3", "app.py"]