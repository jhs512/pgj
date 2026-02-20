# PGJ

PostgreSQL 18 + PGroonga + PostGIS + pgvector in a single container.

```
docker pull jangka512/pgj
```

## What's inside

| Component  | Version | Purpose                          |
| ---------- | ------- | -------------------------------- |
| PostgreSQL | 18      | Base database                    |
| PGroonga   | latest  | Full-text search (Groonga-based) |
| PostGIS    | 3.x     | Spatial data                     |
| pgvector   | 0.8.1   | Vector similarity search         |

## Quick start

```bash
docker run -d --name pgj \
  -e POSTGRES_PASSWORD=secret \
  -p 5432:5432 \
  jangka512/pgj:latest
```

- **5432** — PostgreSQL

## Environment variables

| Variable             | Default    | Description                                                                       |
| -------------------- | ---------- | --------------------------------------------------------------------------------- |
| `POSTGRES_USER`      | `postgres` | PostgreSQL superuser                                                              |
| `POSTGRES_PASSWORD`  | `postgres` | Superuser password                                                                |
| `POSTGRES_DB`        | `postgres` | Initial database (standard PG behavior)                                           |
| `POSTGRES_DATABASES` | `postgres` | Comma-separated list of databases. Missing databases are auto-created on startup. |

## Multiple databases

```bash
docker run -d --name pgj \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DATABASES=postgres,myapp \
  -p 5432:5432 \
  jangka512/pgj:latest
```

Each database in `POSTGRES_DATABASES` is auto-created if it doesn't exist.

## Docker Compose

```yaml
name: slog_dev
services:
  slog_dev_db:
    image: jangka512/pgj:latest
    container_name: slog_dev_db
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: lldj123414
      POSTGRES_DB: postgres
      POSTGRES_DATABASES: slog_dev,slog_test
      TZ: Asia/Seoul
    command: >
      postgres
      -c fsync=off
      -c synchronous_commit=off
      -c full_page_writes=off
      -c wal_level=minimal
      -c max_wal_senders=0
      -c random_page_cost=1.1
      -c jit=off
      -c log_min_duration_statement=1000
      -c log_statement=all
      -c tcp_keepalives_idle=60
      -c tcp_keepalives_interval=10
      -c tcp_keepalives_count=6
      -c idle_in_transaction_session_timeout=60000
    volumes:
      - db_data:/var/lib/postgresql
volumes:
  db_data:
```

## Extensions

All extensions are auto-enabled on initial database creation:

```sql
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;
```

## Tags

| Tag             | Description        |
| --------------- | ------------------ |
| `latest`        | Most recent build  |
| `v1`, `v2`, ... | Versioned releases |

## Links

- [Docker Hub](https://hub.docker.com/r/jangka512/pgj)
- [PGroonga](https://pgroonga.github.io/)
- [PostGIS](https://postgis.net/)
- [pgvector](https://github.com/pgvector/pgvector)
