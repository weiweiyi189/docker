ARG DING_TKON
FROM node:14.16.0-stretch
RUN apt-get update
RUN apt install -y curl
RUN apt-get clean
RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN sudo sh get-docker.sh
COPY ./send-ding.sh /
CMD sh send-ding.sh -a ${DING_TKON} -t markdown -c pipeine运行成功 -T "title"
