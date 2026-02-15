#!/bin/bash
set -e

# ── Generate pgcat.toml ──────────────────────────────────────────
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DATABASES="${POSTGRES_DATABASES:-postgres}"

mkdir -p /etc/pgcat
envsubst < /etc/pgcat/pgcat.toml.template > /etc/pgcat/pgcat.toml

# Append a pool section for each database in POSTGRES_DATABASES
IFS=',' read -ra _dbs <<< "$POSTGRES_DATABASES"
for db in "${_dbs[@]}"; do
  db="${db// /}"  # trim spaces
  cat >> /etc/pgcat/pgcat.toml <<EOF

[pools.${db}]
pool_mode = "transaction"
default_role = "primary"
query_parser_enabled = true

[pools.${db}.users.0]
username = "${POSTGRES_USER}"
password = "${POSTGRES_PASSWORD}"
pool_size = 10
min_pool_size = 1

[pools.${db}.shards.0]
servers = [["127.0.0.1", 5432, "primary"]]
database = "${db}"
EOF
done

# ── Start PostgreSQL (original entrypoint) in background ───────────
# Forward command args (e.g. postgres -c fsync=off ...), default to "postgres"
if [ $# -eq 0 ]; then
  set -- postgres
fi
docker-entrypoint.sh "$@" &

# ── Wait for PostgreSQL to become ready ────────────────────────────
until pg_isready -U "${POSTGRES_USER}" -q; do
  sleep 1
done

# ── Create missing databases from POSTGRES_DATABASES ─────────────────
for db in "${_dbs[@]}"; do
  db="${db// /}"
  if ! psql -U "${POSTGRES_USER}" -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1; then
    psql -U "${POSTGRES_USER}" -c "CREATE DATABASE \"${db}\""
    echo "pgcat-init: created database '${db}'"
  fi
done

# ── Start pgCat in foreground ──────────────────────────────────────
exec pgcat /etc/pgcat/pgcat.toml
