FROM groonga/pgroonga:latest-debian-18

# ── PostGIS ──────────────────────────────────────────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates gnupg lsb-release wget \
 && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list' \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg \
 && apt-get update \
 && apt-get install -y --no-install-recommends postgresql-18-postgis-3 \
 && apt-get purge -y --auto-remove gnupg lsb-release wget \
 && rm -rf /var/lib/apt/lists/*

# ── pgvector (build from source) ─────────────────────────────────────
ARG PGVECTOR_VERSION=0.8.1
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential git postgresql-server-dev-18 \
 && git clone --branch v${PGVECTOR_VERSION} --depth 1 \
        https://github.com/pgvector/pgvector.git /tmp/pgvector \
 && cd /tmp/pgvector && make OPTFLAGS="" && make install \
 && apt-get purge -y --auto-remove build-essential git postgresql-server-dev-18 \
 && rm -rf /tmp/pgvector /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

# ── healthcheck ──────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

# ── init extensions ──────────────────────────────────────────────────
COPY initdb.d/ /docker-entrypoint-initdb.d/

EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
