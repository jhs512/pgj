# PGJ

PostgreSQL 18 + PGroonga + PostGIS + pgvector + pgCat in a single container.

```
docker pull jangka512/pgj
```

## What's inside

| Component | Version | Purpose |
|-----------|---------|---------|
| PostgreSQL | 18 | Base database |
| PGroonga | latest | Full-text search (Groonga-based) |
| PostGIS | 3.x | Spatial data |
| pgvector | 0.8.1 | Vector similarity search |
| pgCat | 0.2.5 | Connection pooling |

## Quick start

```bash
docker run -d --name pgj \
  -e POSTGRES_PASSWORD=secret \
  -p 5432:5432 \
  -p 6432:6432 \
  jangka512/pgj:latest
```

- **5432** — PostgreSQL direct
- **6432** — pgCat connection pooler

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `postgres` | PostgreSQL superuser |
| `POSTGRES_PASSWORD` | `postgres` | Superuser password |
| `POSTGRES_DB` | `postgres` | Initial database (standard PG behavior) |
| `POSTGRES_DATABASES` | `postgres` | Comma-separated list of databases to pool via pgCat. Missing databases are auto-created on startup. |

## Multiple databases

```bash
docker run -d --name pgj \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DATABASES=postgres,myapp \
  -p 5432:5432 \
  -p 6432:6432 \
  jangka512/pgj:latest
```

Each database in `POSTGRES_DATABASES` gets:
- A pgCat connection pool (transaction mode, pool size 10)
- Auto-created if it doesn't exist

## Extensions

All extensions are auto-enabled on initial database creation:

```sql
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;
```

## pgCat

- Pool mode: transaction
- Pool size: 10 per database
- Admin credentials: same as `POSTGRES_USER` / `POSTGRES_PASSWORD`

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent build |
| `v1`, `v2`, ... | Versioned releases |

## Links

- [Docker Hub](https://hub.docker.com/r/jangka512/pgj)
- [PGroonga](https://pgroonga.github.io/)
- [PostGIS](https://postgis.net/)
- [pgvector](https://github.com/pgvector/pgvector)
- [pgCat](https://github.com/postgresml/pgcat)
