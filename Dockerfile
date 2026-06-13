# ---- Build Stage ----
FROM node:20-alpine AS builder

WORKDIR /app

COPY app/package*.json ./
RUN npm ci --only=production && npm cache clean --force

# ---- Production Stage ----
FROM node:20-alpine AS production

# Install security updates
RUN apk --no-cache upgrade

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only production deps and source
COPY --from=builder /app/node_modules ./node_modules
COPY app/src ./src

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENV NODE_ENV=dev

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "src/index.js"]
