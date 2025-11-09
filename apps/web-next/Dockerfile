FROM node:20-alpine
WORKDIR /app
COPY apps/web-next/package.json apps/web-next/package-lock.json ./
RUN npm ci || npm install
COPY apps/web-next .
EXPOSE 3000
CMD ["npm", "run", "dev"]
