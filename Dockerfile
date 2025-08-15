## UI build stage
FROM node:20-alpine AS builder
# Set working directory for the build
WORKDIR /app

# Install dependencies first (better caching)
# - copying lockfile allows npm ci to leverage cache layers
COPY package.json package-lock.json ./
# Clean, reproducible install without audit prompts
RUN npm ci --no-audit --no-fund

# Copy source
# Copy all project files to the builder image
COPY . .

# Accept build-time API URLs; Vite reads these at build time
ARG VITE_USER_SERVICE_URL
ARG VITE_PRODUCT_SERVICE_URL
ARG VITE_CART_SERVICE_URL
ARG VITE_ORDER_SERVICE_URL
ENV VITE_USER_SERVICE_URL=${VITE_USER_SERVICE_URL}
ENV VITE_PRODUCT_SERVICE_URL=${VITE_PRODUCT_SERVICE_URL}
ENV VITE_CART_SERVICE_URL=${VITE_CART_SERVICE_URL}
ENV VITE_ORDER_SERVICE_URL=${VITE_ORDER_SERVICE_URL}

# Build static assets
# Outputs to /app/dist
RUN npm run build

## Runtime stage
FROM nginx:alpine
# Copy SPA nginx config with history fallback
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80
# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]


