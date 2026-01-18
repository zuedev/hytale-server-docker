#!/bin/sh

# set default parameters for Hytale server
HYTALE_PARAMETERS=${HYTALE_PARAMETERS:-"-jar /app/Hytale/Server/HytaleServer.jar --assets /app/Hytale/Assets.zip"}

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

# Start the Hytale server
exec java $HYTALE_PARAMETERS
