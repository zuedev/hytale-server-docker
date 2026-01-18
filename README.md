# Hytale Server Docker

> 🐳 Alpine-based Docker image for Hytale servers with auto-setup and OAuth2 support.

This repository provides a Docker image to easily set up and run a Hytale server using Docker. The image is based on Alpine Linux for a lightweight footprint and includes an automatic setup process that downloads the necessary server files.

## Usage

I recommend using Docker Compose for easy management of the Hytale server container. Create a `docker-compose.yml` file with the following content:

```yaml
services:
  hytale:
    image: ghcr.io/zuedev/hytale-server-docker
    ports:
      - "5520:5520/udp"
    volumes:
      - ./Hytale:/app/Hytale
    restart: unless-stopped
    stdin_open: true
    tty: true
```

Then, run the following command to start the server:

```bash
docker compose up -d
```

Then you will need to check the container logs to see the progress of the server setup, as well as authentication instructions:

```bash
docker compose logs -f hytale
```

Once the Hytale server itself is downloaded and running, you will need to attach to it to complete the OAuth2 setup:

```bash
docker compose attach hytale
```

Type `auth login device` in the container terminal and follow the instructions to authenticate your server. Once authenticated, you can detach from the container by pressing `Ctrl + P` followed by `Ctrl + Q`.

### Authentication Persistence

I recommend running `auth persistence Encrypted` within the container to ensure that your authentication tokens are saved securely and persist across container restarts. Make sure to reauthenticate after running this command to store the tokens.

## Legal

This project is not affiliated with or endorsed by Hypixel Studios. Hytale and all related trademarks are the property of their respective owners. This project is intended for educational and personal use only.

### License

This project is released into the public domain under [The Unlicense](LICENSE).
