#!/usr/bin/env bash

# Chainweb Node Startup Script
# Optimized for Flux deployment with compacted database

# Environment variables with defaults
export CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-mainnet01}
export CHAINWEB_P2P_PORT=${CHAINWEB_P2P_PORT:-1789}
export CHAINWEB_SERVICE_PORT=${CHAINWEB_SERVICE_PORT:-1848}
export CHAINWEB_P2P_HOST=${CHAINWEB_P2P_HOST:-0.0.0.0}
export LOGLEVEL=${LOGLEVEL:-warn}
export MINER_KEY=${MINER_KEY:-}
export MINER_ACCOUNT=${MINER_ACCOUNT:-$MINER_KEY}

# Check ulimit
UL=$(ulimit -n -S)
if [[ "$UL" -lt 65536 ]]; then
    echo "WARNING: Open file limit is $UL, recommended minimum is 65536" >&2
    echo "Container should be started with: --ulimit nofile=65536:65536" >&2
fi

# Ensure database directory exists
DBDIR="/data/chainweb-db"
mkdir -p "$DBDIR/0"

# Read compaction heights from database if available
SQLITE_COMPACTION=""
ROCKSDB_COMPACTION=""
if [ -f "$DBDIR/0/sqlite/COMPACTION_HEIGHT" ]; then
    SQLITE_COMPACTION=$(cat "$DBDIR/0/sqlite/COMPACTION_HEIGHT" 2>/dev/null | tr -d '[:space:]')
fi
if [ -f "$DBDIR/0/rocksDb/COMPACTION_HEIGHT" ]; then
    ROCKSDB_COMPACTION=$(cat "$DBDIR/0/rocksDb/COMPACTION_HEIGHT" 2>/dev/null | tr -d '[:space:]')
fi
# Use the RocksDB compaction height as the starting point (it has all headers up to this point)
COMPACTION_HEIGHT="${ROCKSDB_COMPACTION:-$SQLITE_COMPACTION}"

# Create miner config file
MINER_CONFIG_FILE=$(mktemp)
if [[ -z "$MINER_KEY" ]]; then
    cat > "$MINER_CONFIG_FILE" << EOF
chainweb:
  mining:
    coordination:
      enabled: ${MINING_ENABLED:-false}
EOF
else
    cat > "$MINER_CONFIG_FILE" << EOF
chainweb:
  mining:
    coordination:
      enabled: true
      miners:
        - account: $MINER_ACCOUNT
          public-keys: [ $MINER_KEY ]
          predicate: keys-all
EOF
fi

echo "=== Starting Chainweb Node ==="
echo "Network: $CHAINWEB_NETWORK"
echo "P2P Port: $CHAINWEB_P2P_PORT"
echo "Service Port: $CHAINWEB_SERVICE_PORT"
echo "Log Level: $LOGLEVEL"
echo "Mining: ${MINER_KEY:+enabled}${MINER_KEY:-disabled}"
echo "SQLite Compaction Height: ${SQLITE_COMPACTION:-unknown}"
echo "RocksDB Compaction Height: ${ROCKSDB_COMPACTION:-unknown}"
echo "Starting from height: ${COMPACTION_HEIGHT:-unknown}"

# Build arguments array
ARGS=(
    --config-file=chainweb.yaml
    --config-file="$MINER_CONFIG_FILE"
    --no-full-historic-pact-state
    --prune-chain-database=none
    --bootstrap-reachability=0
    --p2p-hostname="$CHAINWEB_P2P_HOST"
    --p2p-port="$CHAINWEB_P2P_PORT"
    --service-port="$CHAINWEB_SERVICE_PORT"
    --log-level="$LOGLEVEL"
)

# Add initial block height limit if we have a compaction height
# This tells the node to start from a known point in the compacted database
if [[ -n "$COMPACTION_HEIGHT" ]]; then
    ARGS+=(--initial-block-height-limit="$COMPACTION_HEIGHT")
fi

# Run chainweb-node
exec ./chainweb-node "${ARGS[@]}" +RTS -N -t -A64M -H500M -RTS "$@"
