#!/usr/bin/env bash

# Health check script for Chainweb node
# Verifies node is synced within acceptable range

export CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-mainnet01}
export CHAINWEB_P2P_PORT=${CHAINWEB_P2P_PORT:-1789}

# Calculate expected block height based on time
# Base values from a known point in time
CURRENT_TIME=$(date '+%s')
BASE_TIME=1734220800  # 2024-12-15 00:00:00 UTC
BASE_HEIGHT=128000000 # Approximate height at that time

# Chainweb produces ~20 blocks per 30 seconds (20 chains)
TIME_DIFF=$((CURRENT_TIME - BASE_TIME))
BLOCKS_PASSED=$((TIME_DIFF / 30 * 20))
EXPECTED_HEIGHT=$((BASE_HEIGHT + BLOCKS_PASSED))

# Allow 4800 blocks behind (about 2 hours of sync lag)
MIN_ACCEPTED_HEIGHT=$((EXPECTED_HEIGHT - 4800))

# Get current node height
CURRENT_HEIGHT=$(curl -fskL "https://localhost:${CHAINWEB_P2P_PORT}/chainweb/0.0/${CHAINWEB_NETWORK}/cut" 2>/dev/null | jq -r '.height // 0')

if [[ -z "$CURRENT_HEIGHT" ]] || [[ "$CURRENT_HEIGHT" == "0" ]] || [[ "$CURRENT_HEIGHT" == "null" ]]; then
    echo "ERROR: Could not get node height"
    exit 1
fi

if ((CURRENT_HEIGHT >= MIN_ACCEPTED_HEIGHT)); then
    echo "OK: Node height ${CURRENT_HEIGHT} (minimum: ${MIN_ACCEPTED_HEIGHT})"
    exit 0
else
    echo "SYNCING: Node height ${CURRENT_HEIGHT}, need ${MIN_ACCEPTED_HEIGHT}"
    exit 1
fi
