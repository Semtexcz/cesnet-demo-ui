# build stage
FROM node:lts-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN yarn install
COPY . .
RUN yarn build
#ENTRYPOINT [ "./node_modules/.bin/quasar" ]