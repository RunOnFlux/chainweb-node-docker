# Chainweb Node Docker Image (Compacted Database)
# Optimized for Flux deployment with minimal storage requirements
#
# Run with: --ulimit nofile=65536:65536

ARG UBUNTUVER=22.04

FROM ubuntu:${UBUNTUVER}

ARG CHAINWEB_VERSION=3.0.1
ARG GHCVER=9.8.2
ARG REVISION=e60dd0f
ARG UBUNTUVER

LABEL maintainer="RunOnFlux"
LABEL chainweb.version="${CHAINWEB_VERSION}"
LABEL ghc.version="${GHCVER}"
LABEL ubuntu.version="${UBUNTUVER}"

# Install runtime dependencies + nginx for dashboard
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        rsync \
        openssl \
        xxd \
        locales \
        libtbb2 \
        libmpfr6 \
        libgmp10 \
        libssl3 \
        libsnappy1v5 \
        zlib1g \
        liblz4-1 \
        libbz2-1.0 \
        libgflags2.2 \
        zstd \
        nginx \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

# Install chainweb-node binary
WORKDIR /chainweb
RUN curl -fsSL "https://github.com/kda-community/chainweb-node/releases/download/${CHAINWEB_VERSION}/chainweb-${CHAINWEB_VERSION}.ghc-${GHCVER}.ubuntu-${UBUNTUVER}.${REVISION}.tar.gz" \
    | tar -xzC "/chainweb/"

# Copy scripts and config
COPY initialize-db.sh run-chainweb-node.sh check-health.sh check-reachability.sh chainweb.yaml start.sh ./
RUN chmod 755 initialize-db.sh run-chainweb-node.sh check-health.sh check-reachability.sh start.sh

# Copy dashboard
COPY dashboard/ /var/www/html/
COPY nginx.conf /etc/nginx/sites-available/default
RUN chmod 644 /var/www/html/*.html

# Create data directories
RUN mkdir -p /data/chainweb-db/0

STOPSIGNAL SIGTERM

# Default ports: P2P, Service API, Dashboard
EXPOSE 1789 1848 8080

HEALTHCHECK --start-period=15m --interval=1m --retries=5 --timeout=15s \
    CMD ./check-health.sh

CMD ["./start.sh"]
