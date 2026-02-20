#!/bin/bash
set -e

docker-entrypoint.sh "$@" &

until pg_isready -U "${POSTGRES_USER:-postgres}" -q; do
  sleep 1
done

if [ -n "$POSTGRES_DATABASES" ]; then
  IFS=',' read -ra _dbs <<< "$POSTGRES_DATABASES"
  for db in "${_dbs[@]}"; do
    psql -U "${POSTGRES_USER:-postgres}" -tc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1 || \
      psql -U "${POSTGRES_USER:-postgres}" -c "CREATE DATABASE \"$db\""
  done
fi

wait
