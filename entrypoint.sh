#!/bin/sh

# Download Hytale server files if not already present
if [ ! -f "HytaleServer.jar" ]; then
    echo "Downloading Hytale server files..."
    ./hytale-downloader-linux-amd64 \
        --session-token "$HYTALE_SERVER_SESSION_TOKEN" \
        --identity-token "$HYTALE_SERVER_IDENTITY_TOKEN" \
        --owner-uuid "$HYTALE_SERVER_OWNER_UUID"
fi

# Start the Hytale server
exec java -jar HytaleServer.jar --assets Assets.zip "$@"
