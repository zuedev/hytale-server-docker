#!/bin/sh

# Extract total memory in MB
SYSTEM_TOTAL_MEMORY=$(free -m | awk '/^Mem:/ {print $2}')
SYSTEM_TOTAL_MEMORY=${SYSTEM_TOTAL_MEMORY:-4096}  # fallback to 4GB if free command fails

# Set minimum memory to 128M if not specified
HYTALE_MINIMUM_MEMORY=${HYTALE_MINIMUM_MEMORY:-128M}

# Set maximum memory to 90% of total system memory if not specified
HYTALE_MAXIMUM_MEMORY=${HYTALE_MAXIMUM_MEMORY:-$(($SYSTEM_TOTAL_MEMORY * 90 / 100))M}

# Set default server port if not specified
HYTALE_SERVER_PORT=${HYTALE_SERVER_PORT:-5520}

# set default parameters for Hytale server
HYTALE_PARAMETERS=${HYTALE_PARAMETERS:-"-XX:AOTCache=/app/Hytale/Server/HytaleServer.aot -Xms${HYTALE_MINIMUM_MEMORY} -Xmx${HYTALE_MAXIMUM_MEMORY} -jar /app/Hytale/Server/HytaleServer.jar --assets /app/Hytale/Assets.zip --bind 0.0.0.0:${HYTALE_SERVER_PORT}"}

# do we have any additional parameters to append?
if [ ! -z "$HYTALE_ADDITIONAL_PARAMETERS" ]; then
    HYTALE_PARAMETERS="$HYTALE_PARAMETERS $HYTALE_ADDITIONAL_PARAMETERS"
fi

# Download Hytale server files if not already present
if [ ! -f "/app/Hytale/Server/HytaleServer.jar" ]; then
    echo "Hytale server files not found. Downloading..."
    ./hytale-downloader-linux-amd64 -download-path /tmp/HytaleServer.zip
else
    echo "Hytale server files already present. Skipping download."
fi

# Unzip the server files
if [ -f "/tmp/HytaleServer.zip" ]; then
    echo "Unzipping Hytale server files..."
    unzip -o /tmp/HytaleServer.zip -d /app/Hytale/
    rm /tmp/HytaleServer.zip
else 
    echo "No Hytale server zip file found to unzip."
fi

if [ -f /app/Hytale/config.json ] && [ -n "$HYTALE_MAX_VIEW_RADIUS" ]; then
    sed -i "s/\"MaxViewRadius\"[[:space:]]*:[[:space:]]*[0-9.]\+/\"MaxViewRadius\": $HYTALE_MAX_VIEW_RADIUS/" /app/Hytale/config.json
fi

# Start the Hytale server
exec java $HYTALE_PARAMETERS
