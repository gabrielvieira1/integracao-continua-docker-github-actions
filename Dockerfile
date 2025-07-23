FROM ubuntu:latest

EXPOSE 8000

WORKDIR /app

COPY ./main main

RUN chmod +x main

COPY ./templates/ templates

CMD [ "./main" ]
