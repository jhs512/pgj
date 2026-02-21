#!/bin/bash
set -e

# DB 생성 로직을 백그라운드에서 실행 (실제 서버가 TCP 리슨을 시작한 후)
if [ -n "$POSTGRES_DATABASES" ]; then
  (
    # 실제 서버가 TCP 포트에서 리슨할 때까지 대기
    until pg_isready -U "${POSTGRES_USER:-postgres}" -h 127.0.0.1 -q; do
      sleep 1
    done

    IFS=',' read -ra _dbs <<< "$POSTGRES_DATABASES"
    for db in "${_dbs[@]}"; do
      psql -U "${POSTGRES_USER:-postgres}" -h 127.0.0.1 -tc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1 || \
        psql -U "${POSTGRES_USER:-postgres}" -h 127.0.0.1 -c "CREATE DATABASE \"$db\""
    done
  ) &
fi

exec docker-entrypoint.sh "$@"
