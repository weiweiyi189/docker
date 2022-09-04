FROM node:14.16.0-stretch
RUN apt-get update
RUN apt install -y curl
RUN apt-get clean
COPY ./send-ding.sh /
RUN sh send-ding.sh -a 1ab5179dd94ed62de026d96ba61b41b1dda42357fdf79a787f11c7708449a06d -t markdown -c pipeine运行失败 -T "tiTle"
