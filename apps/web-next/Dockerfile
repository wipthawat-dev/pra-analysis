FROM node:20-alpine
WORKDIR /app
# Copy package.json first (and package-lock.json if it exists)
COPY apps/web-next/package.json ./
COPY apps/web-next/package-lock.json* ./
# Install dependencies
RUN npm install
# Copy the rest of the application
COPY apps/web-next .
EXPOSE 3000
CMD ["npm", "run", "dev"]
