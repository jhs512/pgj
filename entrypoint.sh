#!/bin/bash
set -e

export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DATABASES="${POSTGRES_DATABASES:-postgres}"

# ── Start PostgreSQL (original entrypoint) in background ───────────
if [ $# -eq 0 ]; then
  set -- postgres
fi
docker-entrypoint.sh "$@" &

# ── Wait for PostgreSQL to become ready ────────────────────────────
until pg_isready -U "${POSTGRES_USER}" -q; do
  sleep 1
done

# ── Create missing databases from POSTGRES_DATABASES ─────────────────
IFS=',' read -ra _dbs <<< "$POSTGRES_DATABASES"
for db in "${_dbs[@]}"; do
  db="${db// /}"
  if ! psql -U "${POSTGRES_USER}" -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1; then
    psql -U "${POSTGRES_USER}" -c "CREATE DATABASE \"${db}\""
    for f in /docker-entrypoint-initdb.d/*.sql; do
      [ -f "$f" ] && psql -U "${POSTGRES_USER}" -d "${db}" -f "$f"
    done
    echo "pgj-init: created database '${db}' with extensions"
  fi
done

# ── Keep PostgreSQL in foreground ────────────────────────────────────
wait
