FROM node:14.16.0-stretch
ARG DING_TKON
RUN apt-get update
RUN apt install -y curl
RUN apt-get clean
COPY ./send-ding.sh /
CMD sh send-ding.sh -a ${DING_TKON} -t markdown -c pipeine运行成功 -T "title"
