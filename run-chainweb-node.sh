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
echo "Base Compaction Height: ${COMPACTION_HEIGHT:-unknown}"

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

# Compacted databases require initial-block-height-limit on every start
# Check for saved height from previous run to resume where we left off
LAST_HEIGHT_FILE="$DBDIR/.last_height"
SAVED_HEIGHT=""
if [ -f "$LAST_HEIGHT_FILE" ]; then
    SAVED_HEIGHT=$(cat "$LAST_HEIGHT_FILE" 2>/dev/null | tr -d '[:space:]')
fi

# Use saved height if it's higher than compaction height, otherwise use compaction height
START_HEIGHT="$COMPACTION_HEIGHT"
if [[ -n "$SAVED_HEIGHT" ]] && [[ "$SAVED_HEIGHT" =~ ^[0-9]+$ ]] && [[ -n "$COMPACTION_HEIGHT" ]] && [[ "$SAVED_HEIGHT" -gt "$COMPACTION_HEIGHT" ]]; then
    START_HEIGHT="$SAVED_HEIGHT"
    echo "Resuming from saved height: $START_HEIGHT (was at compaction height $COMPACTION_HEIGHT)"
fi

if [[ -n "$START_HEIGHT" ]]; then
    echo "Using compacted database, starting from height $START_HEIGHT"
    ARGS+=(--initial-block-height-limit="$START_HEIGHT")
fi

# Background process to save current height periodically
save_height() {
    while true; do
        sleep 300  # Save every 5 minutes
        HEIGHT=$(curl -sf "http://127.0.0.1:${CHAINWEB_SERVICE_PORT}/chainweb/0.0/mainnet01/cut" 2>/dev/null | jq -r '.hashes."0".height // empty')
        if [[ -n "$HEIGHT" ]] && [[ "$HEIGHT" =~ ^[0-9]+$ ]] && [[ "$HEIGHT" -gt 0 ]]; then
            echo "$HEIGHT" > "$LAST_HEIGHT_FILE"
        fi
    done
}

# Start height saver in background
save_height &
HEIGHT_SAVER_PID=$!

# Cleanup on exit - save final height
cleanup() {
    kill $HEIGHT_SAVER_PID 2>/dev/null
    # Save final height on shutdown
    HEIGHT=$(curl -sf "http://127.0.0.1:${CHAINWEB_SERVICE_PORT}/chainweb/0.0/mainnet01/cut" 2>/dev/null | jq -r '.hashes."0".height // empty')
    if [[ -n "$HEIGHT" ]] && [[ "$HEIGHT" =~ ^[0-9]+$ ]] && [[ "$HEIGHT" -gt 0 ]]; then
        echo "$HEIGHT" > "$LAST_HEIGHT_FILE"
        echo "Saved height $HEIGHT on shutdown"
    fi
}
trap cleanup EXIT INT TERM

# Run chainweb-node in foreground
./chainweb-node "${ARGS[@]}" +RTS -N -t -A64M -H500M -RTS "$@" &
NODE_PID=$!

# Wait for node and propagate exit code
wait $NODE_PID
EXIT_CODE=$?
exit $EXIT_CODE
