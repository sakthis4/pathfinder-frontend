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

# Healthcheck defined in docker-compose.yml (overrides Dockerfile HEALTHCHECK)
CMD ["nginx", "-g", "daemon off;"]
