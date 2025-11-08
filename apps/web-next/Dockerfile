FROM node:20-alpine
WORKDIR /app
COPY apps/web-next/package.json apps/web-next/pnpm-lock.yaml ./
RUN npm i -g pnpm && pnpm install --frozen-lockfile || true
COPY apps/web-next .
EXPOSE 3000
CMD ["pnpm", "dev", "--host"]
