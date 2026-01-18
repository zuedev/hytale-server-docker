# Base image
FROM alpine:3.23

# Set working directory
WORKDIR /app

# Install dependencies and download Hytale server in a single layer
RUN apk add --no-cache \
        openjdk25-jre \
        gcompat \
        libc6-compat \
        libgcc \
        libstdc++ \
    && wget -q https://downloader.hytale.com/hytale-downloader.zip \
    && unzip hytale-downloader.zip hytale-downloader-linux-amd64 \
    && rm hytale-downloader.zip

# Copy and prepare entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose default Hytale server port
EXPOSE 5520

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
