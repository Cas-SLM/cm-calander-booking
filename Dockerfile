FROM node:25-alpine AS builder

WORKDIR /build

COPY package.json ./
COPY tsconfig.json ./
COPY src/ ./src/

RUN npm install -g pnpm
RUN pnpm install

RUN npm run build
RUN npm prune --omit-dev

FROM gcr.io/distroless/nodejs22-debian13 AS production

WORKDIR /app

COPY --from=builder /build/package*.json ./
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/dist ./dist

EXPOSE 3000

CMD ["dist/main.js"]

