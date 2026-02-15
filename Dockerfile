# ============================================================================
# Build Stage - Compile Elixir application and create release
# ============================================================================
FROM hexpm/elixir:1.15.7-erlang-26.2.1-alpine-3.18.4 AS builder

# Set build environment
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev

WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files first for better caching
COPY mix.exs mix.lock* ./

# Fetch and compile dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy configuration files
COPY config config

# Copy source code
COPY lib lib
RUN mkdir -p priv

# Compile the application
RUN mix compile

# Create the release
RUN mix release huddle_service

# ============================================================================
# Runtime Stage - Minimal production image
# ============================================================================
FROM alpine:3.18

# Set runtime environment
ENV LANG=C.UTF-8 \
    MIX_ENV=prod \
    PORT=4005 \
    RELEASE_NODE=huddle_service \
    PHX_SERVER=true

# Install runtime dependencies
RUN apk add --no-cache \
    libstdc++ \
    openssl \
    ncurses-libs \
    libgcc \
    curl \
    bash \
    && addgroup -g 1000 elixir \
    && adduser -u 1000 -G elixir -s /bin/sh -D elixir

WORKDIR /app

# Copy release from builder stage
COPY --from=builder --chown=elixir:elixir /app/_build/prod/rel/huddle_service ./

# Switch to non-root user
USER elixir

# Expose HTTP port and EPMD port for distributed Erlang
EXPOSE 4005 4369

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4005/health || exit 1

# Start the release
CMD ["bin/huddle_service", "start"]
