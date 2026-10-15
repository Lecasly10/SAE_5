FROM node:22-slim

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY backend ./backend

WORKDIR /app/backend

EXPOSE 3000

CMD ["node", "server.js"]
