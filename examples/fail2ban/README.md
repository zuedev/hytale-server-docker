# Hytale Server with fail2ban Protection

This example demonstrates how to protect your Hytale server from abuse using fail2ban in a sidecar container.

## How It Works

1. **Hytale server** runs and writes logs to a shared volume
2. **fail2ban** monitors those logs for suspicious patterns
3. When an IP exceeds the failure threshold, fail2ban adds an iptables rule to block it

## Requirements

- Docker with host network access (for iptables management)
- Linux host (fail2ban needs iptables access)
- `NET_ADMIN` and `NET_RAW` capabilities

> ⚠️ **Note**: fail2ban with Docker works best on Linux hosts. On Windows/macOS with Docker Desktop, iptables rules won't work as expected due to the VM layer.

## Configuration

### Jail Configuration (`fail2ban/jail.d/hytale.local`)

| Setting    | Default | Description                                |
| ---------- | ------- | ------------------------------------------ |
| `bantime`  | 3600    | Ban duration in seconds (1 hour)           |
| `findtime` | 600     | Time window to count failures (10 minutes) |
| `maxretry` | 5       | Number of failures before ban              |

### Filter Configuration (`fail2ban/filter.d/hytale.local`)

**Important**: The filter regex patterns are templates. You need to customize them based on actual Hytale server log output.

To find the correct patterns:

1. Start your server and check the logs:

   ```bash
   docker compose up -d
   docker compose logs -f hytale
   ```

2. Look for log entries related to:
   - Failed authentication attempts
   - Invalid packets
   - Connection errors
   - Kicked players

3. Update the `failregex` patterns to match those log formats

## Usage

```bash
# Start the services
docker compose up -d

# Check fail2ban status
docker compose exec fail2ban fail2ban-client status

# Check hytale jail status
docker compose exec fail2ban fail2ban-client status hytale

# Manually unban an IP
docker compose exec fail2ban fail2ban-client set hytale unbanip <IP>

# View banned IPs
docker compose exec fail2ban fail2ban-client get hytale banip
```

## UDP Considerations

Hytale uses UDP for its game protocol. fail2ban handles this by:

1. Using `protocol = udp` in the jail configuration
2. Using `iptables-allports[protocol=udp]` as the ban action

This ensures that iptables rules are created for UDP traffic specifically.

## Alternative: Host-Level fail2ban

If you prefer to run fail2ban on the host instead of in a container:

1. Install fail2ban on your host:

   ```bash
   # Debian/Ubuntu
   sudo apt install fail2ban

   # RHEL/CentOS/Fedora
   sudo dnf install fail2ban
   ```

2. Copy the filter and jail files to host directories:

   ```bash
   sudo cp fail2ban/filter.d/hytale.local /etc/fail2ban/filter.d/
   sudo cp fail2ban/jail.d/hytale.local /etc/fail2ban/jail.d/
   ```

3. Update the `logpath` in the jail file to point to your Docker volume location

4. Restart fail2ban:
   ```bash
   sudo systemctl restart fail2ban
   ```

## Troubleshooting

### fail2ban not banning IPs

1. Check if the filter matches your logs:

   ```bash
   docker compose exec fail2ban fail2ban-regex /var/log/hytale/server.log /data/filter.d/hytale.local
   ```

2. Verify iptables rules are being created:
   ```bash
   docker compose exec fail2ban iptables -L -n
   ```

### Logs not appearing

Ensure the Hytale server is writing logs to the shared volume at `/app/Hytale/logs/`.

### Permission issues

The fail2ban container needs `NET_ADMIN` capability to manage iptables.
