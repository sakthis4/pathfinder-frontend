# =============================================================================
# Pathfinder Frontend — Multi-stage Dockerfile
# Builds React SPA and serves via nginx on port 5000
# =============================================================================

# --- Build stage ---
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

# --- Production stage ---
FROM nginx:alpine AS production

# Copy built assets and nginx config
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO /dev/null http://localhost:5000/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
