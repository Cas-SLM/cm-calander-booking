FROM node:25-alpine AS builder

WORKDIR /build

RUN corepack enable \
 && corepack prepare pnpm@9.12.0 --activate

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile
# RUN pnpm install --shamefully-hoist

COPY tsconfig.json ./
COPY src/ ./src/

RUN pnpm run build

RUN pnpm prune --prod


FROM gcr.io/distroless/nodejs22-debian13 AS production

WORKDIR /app

# COPY --from=builder /build/package.json ./
# COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/dist ./dist

EXPOSE 3000

CMD ["dist/main.js"]