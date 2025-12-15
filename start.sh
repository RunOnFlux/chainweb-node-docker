#!/usr/bin/env bash
# Start script for Kadena node + dashboard
# Runs nginx for dashboard and chainweb-node

set -e

# Get ports from environment
SERVICE_PORT="${CHAINWEB_SERVICE_PORT:-1848}"
P2P_PORT="${CHAINWEB_P2P_PORT:-1789}"
DASHBOARD_PORT="${DASHBOARD_PORT:-8080}"

echo "=== Kadena Node Startup ==="
echo "Service Port: $SERVICE_PORT"
echo "P2P Port: $P2P_PORT"
echo "Dashboard Port: $DASHBOARD_PORT"

# Update nginx config with correct ports
sed -i "s/proxy_pass http:\/\/127.0.0.1:1848/proxy_pass http:\/\/127.0.0.1:${SERVICE_PORT}/g" /etc/nginx/sites-available/default
sed -i "s/proxy_pass https:\/\/127.0.0.1:1789/proxy_pass https:\/\/127.0.0.1:${P2P_PORT}/g" /etc/nginx/sites-available/default
sed -i "s/listen 8080/listen ${DASHBOARD_PORT}/g; s/listen \[::\]:8080/listen [::]:${DASHBOARD_PORT}/g" /etc/nginx/sites-available/default

# Start nginx in background
echo "Starting dashboard server on port $DASHBOARD_PORT..."
nginx

# Check if database exists, initialize if not
if [ -d /data/chainweb-db/0/rocksDb ]; then
    echo "Database found, starting node..."
else
    echo "Database not found, initializing..."
    ./initialize-db.sh
fi

# Start chainweb node (foreground)
echo "Starting chainweb node..."
exec ./run-chainweb-node.sh "$@"
