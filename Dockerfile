FROM node:14.16.0

WORKDIR /root/

COPY package*.json ./

RUN npm install

# 拷贝应用程序
COPY pack.js .
