# =============================================================================
# Pathfinder Frontend — Multi-stage Dockerfile
# Builds React SPA and serves via nginx
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

# Copy custom nginx config
COPY --from=build /app/dist /usr/share/nginx/html

# SPA routing: all paths → index.html
RUN printf 'server {\n\
  listen 80;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location / {\n\
    try_files $uri $uri/ /index.html;\n\
  }\n\
  location /api/ {\n\
    proxy_pass http://app:3002;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
