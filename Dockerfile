# STAGE 1 : On compile l'app
FROM node:20-alpine AS builder
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm prune --omit=dev

# STAGE 2 : On fait l'image finale légère
FROM node:20-alpine
RUN apk add --no-cache wget
WORKDIR /app
COPY --from=builder --chown=node:node /app /app
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["node", "src/server.js"]