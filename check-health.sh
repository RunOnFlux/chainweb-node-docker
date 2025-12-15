#!/usr/bin/env bash

# Health check script for Chainweb node
# Verifies node API is responding with valid data

SERVICE_PORT="${CHAINWEB_SERVICE_PORT:-1848}"

# Get current cut from service API
HEIGHT=$(curl -sf "http://127.0.0.1:${SERVICE_PORT}/chainweb/0.0/mainnet01/cut" 2>/dev/null | jq -r '.hashes."0".height // 0')

if [[ -z "$HEIGHT" ]] || [[ "$HEIGHT" == "0" ]] || [[ "$HEIGHT" == "null" ]]; then
    echo "ERROR: Cannot get node height"
    exit 1
fi

# Check health endpoint
HEALTH=$(curl -sf "http://127.0.0.1:${SERVICE_PORT}/health-check" 2>/dev/null)

if [[ "$HEALTH" == "Health check OK."* ]]; then
    echo "OK: Height ${HEIGHT}"
    exit 0
else
    echo "OK: Height ${HEIGHT} (health endpoint unavailable)"
    exit 0
fi
