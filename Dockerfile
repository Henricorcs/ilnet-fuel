FROM node:20-slim

WORKDIR /app

RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

RUN mkdir -p database public/uploads

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "server.js"]
