FROM ubuntu

LABEL maintainer="huangjinzhuo@gmail.com"

RUN apk update \
  && apk add --virtual build-deps gcc python3-dev musl-dev \
  && apk add postgresql-dev

COPY requirements.txt /requirements.txt

# Installing required modules
RUN pip3 --no-cache-dir install -r /requirements.txt

ENV APP_ROOT '/gorgias-magic'
RUN mkdir -p $APP_ROOT

WORKDIR $APP_ROOT
COPY . $APP_ROOT

EXPOSE 5000

CMD ["python", "app.py"]