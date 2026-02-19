# syntax=docker/dockerfile:1

# ── Builder Stage ────────────────────────────────────────────────────
FROM groonga/pgroonga:latest-debian-18 AS builder

ARG PGVECTOR_VERSION=0.8.1

WORKDIR /tmp/pgvector

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    postgresql-server-dev-18 \
    && rm -rf /var/lib/apt/lists/*

# Build pgvector
RUN git clone --branch v${PGVECTOR_VERSION} --depth 1 https://github.com/pgvector/pgvector.git . \
    && make OPTFLAGS="" \
    && make install DESTDIR=/tmp/install

# ── Final Stage ──────────────────────────────────────────────────────
FROM groonga/pgroonga:latest-debian-18

LABEL maintainer="jangka512"

# Install PostGIS (Runtime dependency)
# Combine apt-get update/install/cleanup to keep layer size small
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        lsb-release \
        wget \
 && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg \
 && apt-get update \
 && apt-get install -y --no-install-recommends postgresql-18-postgis-3 \
 && apt-get purge -y --auto-remove gnupg lsb-release wget \
 && rm -rf /var/lib/apt/lists/*

# Copy compiled pgvector from builder
COPY --from=builder /tmp/install /

# Copy custom scripts
COPY entrypoint.sh /entrypoint.sh
COPY initdb.d/ /docker-entrypoint-initdb.d/

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
