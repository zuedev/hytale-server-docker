# =============================================================================
# STAGE 1: Download and prepare artifacts
# =============================================================================
FROM alpine:3.23 AS downloader

WORKDIR /download

# Install only tools needed for downloading
RUN apk add --no-cache wget unzip

# Download and extract Hytale downloader CLI
RUN wget -q https://downloader.hytale.com/hytale-downloader.zip && \
    unzip hytale-downloader.zip hytale-downloader-linux-amd64 && \
    rm hytale-downloader.zip && \
    chmod +x hytale-downloader-linux-amd64

# =============================================================================
# STAGE 2: Final runtime image
# =============================================================================
FROM alpine:3.23 AS runtime

# Labels for container metadata
LABEL org.opencontainers.image.title="Hytale Server Docker"
LABEL org.opencontainers.image.description="Containerized Hytale dedicated server"
LABEL org.opencontainers.image.source="https://github.com/zuedev/hytale-server-docker"

WORKDIR /app

# Install Java runtime - single layer for cache efficiency
RUN apk add --no-cache openjdk25-jre

# Copy downloader from builder stage
COPY --from=downloader /download/hytale-downloader-linux-amd64 /app/

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create non-root user for security
RUN addgroup -g 1000 hytale && \
    adduser -u 1000 -G hytale -h /app -D hytale && \
    chown -R hytale:hytale /app

USER hytale

# Expose default Hytale server port
EXPOSE 5520

# Health check for container monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "HytaleServer.jar" > /dev/null || exit 1

# Run the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
