#!/usr/bin/env bash
set -e

# Initialize Chainweb database with compacted snapshot from chainweb-community.org
# The compacted database is ~44GB vs ~450GB for full database

DBDIR="/data/chainweb-db"
SNAPSHOT_BASE_URL="${SNAPSHOT_BASE_URL:-https://snapshots.chainweb-community.org/snapshots/compacted}"
SNAPSHOT_RSYNC="${SNAPSHOT_RSYNC:-rsync://snapshots.chainweb-community.org/snapshots/compacted}"

# Get snapshot date (default to today, fallback to yesterday)
get_snapshot_date() {
    local today=$(date -u +%Y-%m-%d)
    local yesterday=$(date -u -d "yesterday" +%Y-%m-%d 2>/dev/null || date -u -v-1d +%Y-%m-%d)

    # Try today first, then yesterday
    for date in "$today" "$yesterday"; do
        if curl -sfI "${SNAPSHOT_BASE_URL}/${date}/rocksDb/" >/dev/null 2>&1; then
            echo "$date"
            return 0
        fi
    done

    # Default to today if checks fail
    echo "$today"
}

# Check if database already exists and is complete
if [ -f "$DBDIR/.download_complete" ] && [ -d "$DBDIR/0/rocksDb" ] && [ -d "$DBDIR/0/sqlite" ]; then
    echo "Database already exists at $DBDIR/0"
    echo "Delete /data/chainweb-db to re-download"
    exit 0
fi

# Clean up any partial/incomplete download
if [ -d "$DBDIR/0" ] && [ ! -f "$DBDIR/.download_complete" ]; then
    echo "Found incomplete database download, cleaning up..."
    rm -rf "$DBDIR/0"
fi

echo "=== Chainweb Compacted Database Initialization ==="
echo "Target directory: $DBDIR"

# Get available snapshot date
SNAPSHOT_DATE=$(get_snapshot_date)
echo "Using snapshot date: $SNAPSHOT_DATE"

mkdir -p "$DBDIR"
cd "$DBDIR"

# Try rsync first (more reliable for large files)
echo "Attempting rsync download..."
if rsync -avz --progress "${SNAPSHOT_RSYNC}/${SNAPSHOT_DATE}/" . 2>/dev/null; then
    echo "Rsync download completed successfully"
else
    echo "Rsync failed, falling back to HTTPS download..."

    # Download rocksDb
    echo "Downloading rocksDb..."
    mkdir -p rocksDb

    # Get list of rocksDb files and download
    for file in $(curl -sf "${SNAPSHOT_BASE_URL}/${SNAPSHOT_DATE}/rocksDb/" | grep -oP 'href="\K[^"]+\.tar\.zst' | sort -u); do
        echo "Downloading rocksDb/${file}..."
        curl -fSL "${SNAPSHOT_BASE_URL}/${SNAPSHOT_DATE}/rocksDb/${file}" -o "rocksDb/${file}"
        echo "Extracting ${file}..."
        zstd -d "rocksDb/${file}" -o "rocksDb/${file%.zst}" && rm "rocksDb/${file}"
        tar -xf "rocksDb/${file%.zst}" -C rocksDb/ && rm "rocksDb/${file%.zst}"
    done

    # Download sqlite
    echo "Downloading sqlite..."
    mkdir -p sqlite

    for file in $(curl -sf "${SNAPSHOT_BASE_URL}/${SNAPSHOT_DATE}/sqlite/" | grep -oP 'href="\K[^"]+\.tar\.zst' | sort -u); do
        echo "Downloading sqlite/${file}..."
        curl -fSL "${SNAPSHOT_BASE_URL}/${SNAPSHOT_DATE}/sqlite/${file}" -o "sqlite/${file}"
        echo "Extracting ${file}..."
        zstd -d "sqlite/${file}" -o "sqlite/${file%.zst}" && rm "sqlite/${file}"
        tar -xf "sqlite/${file%.zst}" -C sqlite/ && rm "sqlite/${file%.zst}"
    done
fi

# Verify download
if [ -d "$DBDIR/0/rocksDb" ] && [ -d "$DBDIR/0/sqlite" ] && \
   [ -f "$DBDIR/0/rocksDb/COMPACTION_HEIGHT" ] && [ -f "$DBDIR/0/sqlite/COMPACTION_HEIGHT" ]; then
    echo "=== Database initialization complete ==="
    echo "RocksDB size: $(du -sh $DBDIR/0/rocksDb 2>/dev/null | cut -f1)"
    echo "SQLite size: $(du -sh $DBDIR/0/sqlite 2>/dev/null | cut -f1)"
    echo "Total size: $(du -sh $DBDIR/0 2>/dev/null | cut -f1)"
    # Create completion marker
    echo "$(date -Iseconds)" > "$DBDIR/.download_complete"
else
    echo "ERROR: Database initialization failed"
    echo "Expected directories $DBDIR/0/rocksDb and $DBDIR/0/sqlite not found"
    # Clean up partial download
    rm -rf "$DBDIR/0"
    exit 1
fi
