# Claw3D - 3D agent visualization for OpenClaw.
# Patched: node:22-slim (camera-controls@3.1.2 requires Node >=22) and keep
# devDependencies (incl. typescript) in the runner so it never lazy-installs
# at container startup — see https://github.com/iamlukethedev/Claw3D upstream
# Dockerfile which used node:20-slim + --omit=dev, causing a runtime crash
# loop when next.config.ts needs a TS transpile it can't fetch.
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_PUBLIC_GATEWAY_URL=ws://127.0.0.1:18789
RUN npm run build

FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/server ./server
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/tsconfig.json ./tsconfig.json

EXPOSE 3000

CMD ["node", "server/index.js"]
