# Chainweb Node Docker (Compacted Database)

Docker image for Kadena Chainweb node using compacted database snapshots from chainweb-community.org.

## Overview

This image runs chainweb-node v3.0.1 with a compacted database (~44GB) instead of the full database (~450GB). Includes a web dashboard and nginx reverse proxy.

## Requirements

- CPU: 4 cores
- RAM: 4 GB
- Storage: 80 GB SSD
- Network: Public IP or port forwarding for P2P

### Limitations

Compacted database does not include full historic Pact state. Some endpoints like `/pool` and `/spv` may not work. Suitable for mining and standard node operations.

## Quick Start

```bash
docker run -d \
    --name chainweb-node \
    --ulimit nofile=65536:65536 \
    -p 8080:8080 \
    -p 1848:1848 \
    -p 1789:1789 \
    -v chainweb-data:/data/chainweb-db \
    runonflux/kadena-chainweb-node:fluxcloud-compacted
```

On first start, the database is downloaded automatically (~15 minutes depending on connection speed).

### Flux Ports

```bash
docker run -d \
    --name chainweb-node \
    --ulimit nofile=65536:65536 \
    -p 31350:31350 \
    -p 31351:31351 \
    -p 31352:31352 \
    -e DASHBOARD_PORT=31350 \
    -e CHAINWEB_SERVICE_PORT=31351 \
    -e CHAINWEB_P2P_PORT=31352 \
    -v chainweb-data:/data/chainweb-db \
    runonflux/kadena-chainweb-node:fluxcloud-compacted
```

## Ports

| Port | Service |
|------|---------|
| 8080 (or 31350) | Dashboard |
| 1848 (or 31351) | Service API |
| 1789 (or 31352) | P2P |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DASHBOARD_PORT` | 8080 | Dashboard port |
| `CHAINWEB_SERVICE_PORT` | 1848 | Service API port |
| `CHAINWEB_P2P_PORT` | 1789 | P2P port |
| `CHAINWEB_P2P_HOST` | 0.0.0.0 | P2P bind address |
| `CHAINWEB_NETWORK` | mainnet01 | Network |
| `LOGLEVEL` | warn | Log level |
| `MINER_KEY` | - | Mining public key |
| `MINER_ACCOUNT` | - | Mining account |

## Flux Deployment

1. Edit `flux-spec.json` and set your ZelID in the `owner` field
2. Update `repotag` to your Docker Hub image
3. Deploy via Flux

Spec: 4 CPU, 4GB RAM, 80GB storage, ports 31350/31351/31352

## Database

Compacted snapshots are downloaded from chainweb-community.org via rsync. The startup script reads the RocksDB compaction height and configures `--initial-block-height-limit` automatically.

To force re-download, delete `/data/chainweb-db` and restart the container.

## API Endpoints

**Service API (port 1848/31351)**
- `GET /health-check`
- `GET /info`
- `GET /chainweb/0.0/mainnet01/cut`

**Dashboard (port 8080/31350)**
- Web interface
- Proxies `/health-check`, `/info`, `/chainweb/*` to service API

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | Container build |
| `start.sh` | Entrypoint |
| `run-chainweb-node.sh` | Node startup |
| `initialize-db.sh` | Database download |
| `chainweb.yaml` | Node config |
| `nginx.conf` | Reverse proxy |
| `dashboard/index.html` | Web dashboard |
| `flux-spec.json` | Flux deployment spec |
| `check-health.sh` | Health check |

## Build

```bash
docker build -t chainweb-node .
```

## Links

- [kda-community/chainweb-node](https://github.com/kda-community/chainweb-node)
- [chainweb-community.org snapshots](https://snapshots.chainweb-community.org/)
- [Kadena docs](https://docs.kadena.io/)
