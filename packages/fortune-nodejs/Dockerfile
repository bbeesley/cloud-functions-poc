FROM node:19-alpine as builder

RUN apk update && apk upgrade && \
    apk add --no-cache openssl ca-certificates wget && \
    apk add --no-cache make gcc g++ python3


RUN mkdir /home/node/app
WORKDIR /home/node/app

COPY .npmrc .npmrc
COPY package.json package.json
COPY package-lock.json package-lock.json

RUN chown -R node:node /home/node/app

USER node
RUN npm ci --omit=dev \
    && rm .npmrc

FROM node:19-alpine

RUN apk update && apk upgrade && apk add --no-cache openssl ca-certificates
RUN update-ca-certificates

USER node

RUN mkdir ~/app
WORKDIR /home/node/app

COPY dist dist
COPY assets assets
COPY package.json package.json
RUN mkdir /home/node/app/node_modules
COPY --from=builder /home/node/app/node_modules ./node_modules/

EXPOSE 8080

CMD /usr/local/bin/npm start
