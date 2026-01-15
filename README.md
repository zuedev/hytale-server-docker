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

## Deployment Examples

### Kubernetes

Deploy a Hytale server on Kubernetes with persistent storage:

```yaml
# hytale-server-deployment.yaml
apiVersion: v1
kind: Secret
metadata:
  name: hytale-server-secrets
type: Opaque
stringData:
  session-token: "<your-session-token>"
  identity-token: "<your-identity-token>"
  owner-uuid: "<your-owner-uuid>"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hytale-server-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hytale-server
  labels:
    app: hytale-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hytale-server
  template:
    metadata:
      labels:
        app: hytale-server
    spec:
      containers:
        - name: hytale-server
          image: ghcr.io/<username>/hytale-server-docker:latest
          ports:
            - containerPort: 5520
              protocol: UDP
          env:
            - name: HYTALE_SERVER_SESSION_TOKEN
              valueFrom:
                secretKeyRef:
                  name: hytale-server-secrets
                  key: session-token
            - name: HYTALE_SERVER_IDENTITY_TOKEN
              valueFrom:
                secretKeyRef:
                  name: hytale-server-secrets
                  key: identity-token
            - name: HYTALE_SERVER_OWNER_UUID
              valueFrom:
                secretKeyRef:
                  name: hytale-server-secrets
                  key: owner-uuid
          volumeMounts:
            - name: server-data
              mountPath: /app/universe
              subPath: universe
            - name: server-data
              mountPath: /app/mods
              subPath: mods
            - name: server-data
              mountPath: /app/logs
              subPath: logs
          resources:
            requests:
              memory: "4Gi"
              cpu: "1"
            limits:
              memory: "8Gi"
              cpu: "4"
      volumes:
        - name: server-data
          persistentVolumeClaim:
            claimName: hytale-server-data
---
apiVersion: v1
kind: Service
metadata:
  name: hytale-server
spec:
  type: LoadBalancer
  selector:
    app: hytale-server
  ports:
    - port: 5520
      targetPort: 5520
      protocol: UDP
```

Apply with:

```bash
kubectl apply -f hytale-server-deployment.yaml
```

### Terraform (AWS ECS)

Deploy to AWS ECS using Terraform:

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "hytale_session_token" {
  sensitive = true
}

variable "hytale_identity_token" {
  sensitive = true
}

variable "hytale_owner_uuid" {
  sensitive = true
}

resource "aws_ecs_cluster" "hytale" {
  name = "hytale-server-cluster"
}

resource "aws_ecs_task_definition" "hytale_server" {
  family                   = "hytale-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"

  container_definitions = jsonencode([
    {
      name      = "hytale-server"
      image     = "ghcr.io/<username>/hytale-server-docker:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5520
          hostPort      = 5520
          protocol      = "udp"
        }
      ]

      environment = [
        {
          name  = "HYTALE_SERVER_SESSION_TOKEN"
          value = var.hytale_session_token
        },
        {
          name  = "HYTALE_SERVER_IDENTITY_TOKEN"
          value = var.hytale_identity_token
        },
        {
          name  = "HYTALE_SERVER_OWNER_UUID"
          value = var.hytale_owner_uuid
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/hytale-server"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "hytale" {
  name              = "/ecs/hytale-server"
  retention_in_days = 7
}

resource "aws_ecs_service" "hytale_server" {
  name            = "hytale-server"
  cluster         = aws_ecs_cluster.hytale.id
  task_definition = aws_ecs_task_definition.hytale_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.hytale.id]
    assign_public_ip = true
  }
}

resource "aws_security_group" "hytale" {
  name        = "hytale-server-sg"
  description = "Security group for Hytale server"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5520
    to_port     = 5520
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "vpc_id" {
  description = "VPC ID for the ECS service"
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS service"
  type        = list(string)
}

output "cluster_name" {
  value = aws_ecs_cluster.hytale.name
}
```

Deploy with:

```bash
terraform init
terraform apply \
  -var="hytale_session_token=<your-token>" \
  -var="hytale_identity_token=<your-token>" \
  -var="hytale_owner_uuid=<your-uuid>" \
  -var="vpc_id=vpc-xxxxx" \
  -var="subnet_ids=[\"subnet-xxxxx\"]"
```

### Ansible

Deploy to a remote server using Ansible:

```yaml
# playbook.yml
---
- name: Deploy Hytale Server
  hosts: game_servers
  become: yes
  vars:
    hytale_server_port: 5520
    hytale_data_path: /opt/hytale
    hytale_image: "ghcr.io/<username>/hytale-server-docker:latest"
  vars_prompt:
    - name: hytale_session_token
      prompt: "Enter Hytale session token"
      private: yes
    - name: hytale_identity_token
      prompt: "Enter Hytale identity token"
      private: yes
    - name: hytale_owner_uuid
      prompt: "Enter Hytale owner UUID"
      private: no

  tasks:
    - name: Install Docker dependencies
      apt:
        name:
          - docker.io
          - docker-compose-plugin
        state: present
        update_cache: yes

    - name: Start and enable Docker service
      systemd:
        name: docker
        state: started
        enabled: yes

    - name: Create Hytale data directories
      file:
        path: "{{ hytale_data_path }}/{{ item }}"
        state: directory
        mode: "0755"
      loop:
        - universe
        - mods
        - logs

    - name: Pull Hytale server image
      community.docker.docker_image:
        name: "{{ hytale_image }}"
        source: pull

    - name: Deploy Hytale server container
      community.docker.docker_container:
        name: hytale-server
        image: "{{ hytale_image }}"
        state: started
        restart_policy: unless-stopped
        ports:
          - "{{ hytale_server_port }}:5520/udp"
        env:
          HYTALE_SERVER_SESSION_TOKEN: "{{ hytale_session_token }}"
          HYTALE_SERVER_IDENTITY_TOKEN: "{{ hytale_identity_token }}"
          HYTALE_SERVER_OWNER_UUID: "{{ hytale_owner_uuid }}"
        volumes:
          - "{{ hytale_data_path }}/universe:/app/universe"
          - "{{ hytale_data_path }}/mods:/app/mods"
          - "{{ hytale_data_path }}/logs:/app/logs"

    - name: Configure firewall for Hytale
      ufw:
        rule: allow
        port: "{{ hytale_server_port }}"
        proto: udp
```

Create an inventory file:

```ini
# inventory.ini
[game_servers]
hytale-server-1 ansible_host=192.168.1.100 ansible_user=ubuntu
```

Run the playbook:

```bash
ansible-playbook -i inventory.ini playbook.yml
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
