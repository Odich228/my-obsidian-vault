FROM node:25-alpine AS builder

WORKDIR /2048-game

COPY package*.json ./
RUN npm install --include=dev

COPY . .
RUN npm run build

EXPOSE 8080

FROM nginx:stable-alpine
COPY --from=builder /2048-game/dist /usr/share/nginx/html