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

# copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# expose default hytale server port
EXPOSE 5520

# run the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
