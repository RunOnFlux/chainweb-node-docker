# syntax=docker/dockerfile:experimental

# Run as
#
# --ulimit nofile=64000:64000

# BUILD PARAMTERS
ARG UBUNTUVER=22.04

FROM ubuntu:${UBUNTUVER}

ARG REVISION=50a69fb
ARG GHCVER=9.8.2
ARG UBUNTUVER

LABEL revision="$REVISION"
LABEL ghc="$GHCVER"
LABEL ubuntu="$UBUNTUVER"

# install prerequisites
RUN apt-get update \
    && apt-get install -y ca-certificates libgmp10 libssl3 libsnappy1v5 zlib1g liblz4-1 libbz2-1.0 libgflags2.2 zstd locales curl jq \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

# Install chainweb applications
WORKDIR /chainweb
# RUN curl -Ls "https://github.com/kadena-io/chainweb-node/releases/download/<chaineweb-version>/<chainweb-binary-version>" | tar -xzC "/chainweb/"
RUN curl -Ls "https://kadena-cabal-cache.s3.amazonaws.com/chainweb-node/chainweb.true.${GHCVER}.ubuntu-${UBUNTUVER}.${REVISION}.tar.gz" | tar -xzC "/"

COPY check-reachability.sh .
COPY run-chainweb-node.sh .
COPY initialize-db.sh .
COPY chainweb.yaml .
COPY check-health.sh .
RUN chmod 755 check-reachability.sh run-chainweb-node.sh initialize-db.sh check-health.sh
RUN mkdir -p /data/chainweb-db
RUN mkdir -p /root/.local/share/chainweb-node/mainnet01/

STOPSIGNAL SIGTERM
EXPOSE 443
EXPOSE 80
EXPOSE 1789
EXPOSE 1848
HEALTHCHECK --start-period=10m --interval=1m --retries=5 --timeout=10s CMD ./check-health.sh

CMD ./run-chainweb-node.sh
