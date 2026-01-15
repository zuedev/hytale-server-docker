# start with a lightweight Alpine Linux image
FROM alpine:3.23

# where we working?
WORKDIR /app

# get apk package manager up to date
RUN apk update

# install java 25 runtime environment, procps for pgrep, and netcat for health checks
RUN apk add --no-cache openjdk25-jre procps netcat-openbsd

# downlaod hytale downloader cli
RUN wget https://downloader.hytale.com/hytale-downloader.zip

# extract hytale-downloader-linux-amd64 cli from zip
RUN unzip hytale-downloader.zip hytale-downloader-linux-amd64

# remove zip file
RUN rm hytale-downloader.zip

# copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# expose default hytale server port
EXPOSE 5520

# health check: verify server process is running and port is available
# checks every 30s, allows 60s startup time, 10s timeout, 3 retries before unhealthy
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "HytaleServer.jar" > /dev/null && nc -z -u localhost 5520 || exit 1

# run the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
