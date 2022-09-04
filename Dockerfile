ARG DING_TKON
FROM node:14.16.0-stretch
RUN apt-get update
RUN apt install -y curl
RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy curl && \
    apt-get install -qy curl && \
    curl -sSL https://get.docker.com/ | sh
RUN apt-get clean
COPY ./send-ding.sh /
CMD sh send-ding.sh -a ${DING_TKON} -t markdown -c pipeine运行成功 -T "title"
