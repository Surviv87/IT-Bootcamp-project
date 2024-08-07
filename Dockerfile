FROM node:19-alpine3.16

RUN apk update && apk --no-cache add curl=8.5.0-r0

WORKDIR /react-app

COPY check_http.sh .

COPY package.json .

COPY package-lock.json .

COPY src src/

COPY public public/

RUN chmod 777 check_http.sh && npm i


EXPOSE 3000

CMD ["npm", "start"]
