# start with a lightweight Alpine Linux image
FROM alpine:3.23

# where we working?
WORKDIR /app

# get apk package manager up to date
RUN apk update

# install java 25 runtime environment
RUN apk add --no-cache openjdk25-jre

# downlaod hytale downloader cli
RUN wget https://downloader.hytale.com/hytale-downloader.zip

# extract hytale-downloader-linux-amd64 cli from zip
RUN unzip hytale-downloader.zip hytale-downloader-linux-amd64

# remove zip file
RUN rm hytale-downloader.zip

# run the hytale downloader cli
RUN ./hytale-downloader-linux-amd64 \
    --session-token $HYTALE_SERVER_SESSION_TOKEN \
    --identity-token $HYTALE_SERVER_IDENTITY_TOKEN \
    --owner-uuid $HYTALE_SERVER_OWNER_UUID

# expose default hytale server port
EXPOSE 5520

# run the hytale server
CMD ["java", "-jar", "HytaleServer.jar"]
