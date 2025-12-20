# ==============================================================================
# Inventory Sync - Production Dockerfile
# Multi-stage build for Elixir/Phoenix release
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build Environment
# ------------------------------------------------------------------------------
ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.2.5
ARG DEBIAN_VERSION=bookworm-20240513-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
# - build-essential: for native extensions (bcrypt_elixir)
# - git: for git-based dependencies
RUN apt-get update -y && apt-get install -y \
    build-essential \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy application source
COPY priv priv
COPY lib lib
COPY assets assets

# Copy runtime config (needed for compilation)
COPY config/runtime.exs config/

# Compile the application first (generates phoenix-colocated hooks)
RUN mix compile

# Compile assets (tailwind + esbuild) - requires colocated hooks from compile step
RUN mix assets.deploy

# Generate release
RUN mix release

# ------------------------------------------------------------------------------
# Stage 2: Runtime Environment
# ------------------------------------------------------------------------------
FROM ${RUNNER_IMAGE}

# Install runtime dependencies
# - libstdc++6: for Erlang NIFs
# - openssl: for crypto
# - libncurses5: for Erlang observer
# - locales: for proper encoding
RUN apt-get update -y && apt-get install -y \
    libstdc++6 \
    openssl \
    libncurses5 \
    locales \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale to en_US.UTF-8
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app
RUN chown -R app:app /app

USER app

# Copy the release from builder stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/inventory_sync ./

# Set runtime environment variables
ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Expose the application port
EXPOSE 4000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Start the Phoenix server
CMD ["bin/inventory_sync", "start"]
