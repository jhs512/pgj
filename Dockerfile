# syntax=docker/dockerfile:1

# ── Builder Stage: pgvector ─────────────────────────────────────────
FROM groonga/pgroonga:latest-debian-18 AS pgvector-builder

ARG PGVECTOR_VERSION=0.8.6

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

# ── Builder Stage: pgvectorscale ────────────────────────────────────
FROM groonga/pgroonga:latest-debian-18 AS pgvectorscale-builder

ARG PGVECTORSCALE_VERSION=0.9.0
ARG CARGO_PGRX_VERSION=0.16.1

# Install LLVM 18 (required by pgrx 0.16.x) and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        libopenblas-dev \
        libssl-dev \
        pkg-config \
        postgresql-server-dev-18 \
        wget \
    && wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key \
       | gpg --dearmor -o /etc/apt/trusted.gpg.d/llvm.gpg \
    && echo "deb https://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-18 main" \
       > /etc/apt/sources.list.d/llvm-18.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        clang-18 \
        llvm-18-dev \
    && rm -rf /var/lib/apt/lists/*

ENV LIBCLANG_PATH=/usr/lib/llvm-18/lib
ENV PATH="/usr/lib/llvm-18/bin:${PATH}"

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

# Install cargo-pgrx matching pgvectorscale's pinned version
RUN cargo install --locked cargo-pgrx --version ${CARGO_PGRX_VERSION}

# Initialize pgrx with system PostgreSQL
RUN cargo pgrx init --pg18=$(which pg_config)

# Clone and build pgvectorscale
RUN git clone --branch ${PGVECTORSCALE_VERSION} --depth 1 \
        https://github.com/timescale/pgvectorscale.git /tmp/pgvectorscale

WORKDIR /tmp/pgvectorscale/pgvectorscale

RUN cargo pgrx install --release --features pg18 --pg-config $(which pg_config)

# ── Final Stage ──────────────────────────────────────────────────────
FROM groonga/pgroonga:latest-debian-18

LABEL maintainer="jangka512"

# Install PostGIS and runtime dependencies
# Combine apt-get update/install/cleanup to keep layer size small
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        libopenblas0 \
        lsb-release \
        wget \
 && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg \
 && apt-get update \
 && apt-get install -y --no-install-recommends postgresql-18-postgis-3 \
 && apt-get purge -y --auto-remove gnupg lsb-release wget \
 && rm -rf /var/lib/apt/lists/*

# Copy compiled pgvector from builder
COPY --from=pgvector-builder /tmp/install /

# Copy compiled pgvectorscale from builder
COPY --from=pgvectorscale-builder /usr/share/postgresql/18/extension/vectorscale* /usr/share/postgresql/18/extension/
COPY --from=pgvectorscale-builder /usr/lib/postgresql/18/lib/vectorscale-0.9.0.so /usr/lib/postgresql/18/lib/

# Copy custom scripts
COPY entrypoint.sh /entrypoint.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
CMD ["postgres", "-c", "shared_preload_libraries=pg_stat_statements,auto_explain", "-c", "auto_explain.log_min_duration=1000"]
