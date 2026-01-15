> [!WARNING]
> This project is still in early development. Use at your own risk, and please report any issues you encounter.

# Hytale Server Docker

A Docker image for running dedicated [Hytale](https://hytale.com/) game servers.

## Features

- 🐳 Lightweight Alpine Linux base image
- ☕ Pre-installed Java 25 (OpenJDK JRE)
- 📦 Automatic server file download via Hytale Downloader CLI
- 🔒 OAuth2 authentication support

## Prerequisites

Before building or running this container, you'll need:

1. **A valid Hytale game license** - Required for server authentication
2. **Authentication tokens** - Obtained through the Hytale OAuth2 device flow (see [Authentication](#authentication))
3. **Docker** - Installed on your host machine

## Quick Start

### 1. Build the Image

```bash
docker build -t hytale-server .
```

### 2. Run the Container

```bash
docker run -d \
  -p 5520:5520/udp \
  -e HYTALE_SERVER_SESSION_TOKEN=<your-session-token> \
  -e HYTALE_SERVER_IDENTITY_TOKEN=<your-identity-token> \
  -e HYTALE_SERVER_OWNER_UUID=<your-owner-uuid> \
  --name hytale-server \
  hytale-server
```

The server files will be automatically downloaded on first start.

> ⚠️ **Important:** Hytale uses the QUIC protocol over **UDP** (not TCP). Make sure to expose the port as UDP.

### 3. Authenticate the Server

After first launch, you need to authenticate your server. Attach to the container and run:

```
/auth login device
```

Follow the on-screen instructions to complete authentication via https://accounts.hytale.com/device

## Configuration

### Environment Variables

These environment variables are required at **runtime** (not build time) to download the server files:

| Variable                       | Description                | Required |
| ------------------------------ | -------------------------- | -------- |
| `HYTALE_SERVER_SESSION_TOKEN`  | OAuth2 session token       | Yes      |
| `HYTALE_SERVER_IDENTITY_TOKEN` | OAuth2 identity token      | Yes      |
| `HYTALE_SERVER_OWNER_UUID`     | Server owner's Hytale UUID | Yes      |

### Ports

| Port | Protocol | Description                |
| ---- | -------- | -------------------------- |
| 5520 | UDP      | Default Hytale server port |

To use a custom port, pass additional arguments to the entrypoint:

```bash
docker run -d \
  -p 25565:25565/udp \
  -e HYTALE_SERVER_SESSION_TOKEN=<your-session-token> \
  -e HYTALE_SERVER_IDENTITY_TOKEN=<your-identity-token> \
  -e HYTALE_SERVER_OWNER_UUID=<your-owner-uuid> \
  --name hytale-server \
  hytale-server \
  --bind 0.0.0.0:25565
```

### Volumes

For data persistence, mount the following directories:

```bash
docker run -d \
  -p 5520:5520/udp \
  -e HYTALE_SERVER_SESSION_TOKEN=<your-session-token> \
  -e HYTALE_SERVER_IDENTITY_TOKEN=<your-identity-token> \
  -e HYTALE_SERVER_OWNER_UUID=<your-owner-uuid> \
  -v ./universe:/app/universe \
  -v ./mods:/app/mods \
  -v ./logs:/app/logs \
  --name hytale-server \
  hytale-server
```

| Path                    | Description                             |
| ----------------------- | --------------------------------------- |
| `/app/universe`         | World and player save data              |
| `/app/mods`             | Installed mods (`.zip` or `.jar` files) |
| `/app/logs`             | Server log files                        |
| `/app/config.json`      | Server configuration                    |
| `/app/permissions.json` | Permission configuration                |
| `/app/bans.json`        | Banned players list                     |
| `/app/whitelist.json`   | Whitelisted players                     |

## Authentication

Hytale servers require authentication to enable communication with Hytale service APIs and to counter abuse.

### Device Flow Authentication

1. Start your server and run `/auth login device`
2. Visit the URL provided (https://accounts.hytale.com/device)
3. Enter the code displayed in the console
4. Complete authorization in your browser

> 📝 **Note:** There is a limit of 100 servers per Hytale game license. For higher capacity needs, purchase additional licenses or apply for a [Server Provider account](https://support.hytale.com/hc/en-us/articles/45328341414043).

## Advanced Usage

### JVM Arguments

To customize JVM arguments, you can override the entrypoint or set `JAVA_OPTS`:

```bash
docker run -d \
  -p 5520:5520/udp \
  -e HYTALE_SERVER_SESSION_TOKEN=<your-session-token> \
  -e HYTALE_SERVER_IDENTITY_TOKEN=<your-identity-token> \
  -e HYTALE_SERVER_OWNER_UUID=<your-owner-uuid> \
  --name hytale-server \
  --entrypoint /bin/sh \
  hytale-server \
  -c "java -Xms4G -Xmx8G -XX:AOTCache=HytaleServer.aot -jar HytaleServer.jar --assets Assets.zip"
```

| Argument                        | Description                            |
| ------------------------------- | -------------------------------------- |
| `-Xms`                          | Initial heap size                      |
| `-Xmx`                          | Maximum heap size                      |
| `-XX:AOTCache=HytaleServer.aot` | Enable AOT cache for faster boot times |

### Disable Sentry (Development)

When developing plugins, disable crash reporting to avoid submitting development errors:

```bash
java -jar HytaleServer.jar --assets Assets.zip --disable-sentry
```

### View Distance

View distance is the main driver for RAM usage. Limit maximum view distance to 12 chunks (384 blocks) for optimal performance:

```bash
# Configure in config.json or via server arguments
```

## System Requirements

| Resource         | Recommendation                                              |
| ---------------- | ----------------------------------------------------------- |
| **RAM**          | Minimum 4GB, adjust based on player count and view distance |
| **CPU**          | Scales with player/entity count                             |
| **Architecture** | x64 and arm64 supported                                     |

## Network Configuration

### Firewall

Hytale uses QUIC over UDP. Ensure your firewall allows UDP traffic on port 5520:

**Linux (ufw):**

```bash
sudo ufw allow 5520/udp
```

**Linux (iptables):**

```bash
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT
```

### Port Forwarding

If hosting behind a router, forward **UDP** port 5520 (or your custom port) to your server machine. TCP forwarding is not required.

## Useful Commands

| Command              | Description                            |
| -------------------- | -------------------------------------- |
| `--help`             | Display all available server arguments |
| `/auth login device` | Authenticate server via device flow    |

View all available arguments:

```bash
java -jar HytaleServer.jar --help
```

## Development

### Building Locally

```bash
docker build -t hytale-server .
```

### CI/CD

This project uses GitHub Actions to automatically build and publish the Docker image to GitHub Container Registry (ghcr.io).

**Triggers:**

- Push to `main` branch
- Version tags (`v*`)
- Pull requests (build only, no push)

**Image Tags:**

| Trigger        | Example Tags                       |
| -------------- | ---------------------------------- |
| Push to `main` | `main`, `sha-abc1234`              |
| Tag `v1.2.3`   | `1.2.3`, `1.2`, `1`, `sha-abc1234` |

**Publishing a Release:**

```bash
git tag v1.0.0
git push origin v1.0.0
```

The image will be available at:

```
ghcr.io/<username>/hytale-server-docker:latest
```

## Resources

- [Official Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)
- [Server Provider Authentication Guide](https://support.hytale.com/hc/en-us/articles/45328341414043)
- [Hytale Downloader CLI](https://downloader.hytale.com/hytale-downloader.zip)
- [Adoptium Java 25](https://adoptium.net/temurin/releases)

## License

This project is open source. See the [LICENSE](LICENSE) file for details.

## Disclaimer

This is an unofficial community project and is not affiliated with or endorsed by Hypixel Studios.
