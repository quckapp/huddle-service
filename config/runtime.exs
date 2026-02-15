import Config

# =============================================================================
# Runtime Configuration for Huddle Service
# =============================================================================
# This file is executed at runtime, after compilation but before the application
# starts. It is evaluated for all environments, including releases.
#
# Environment variables are read here for Docker deployments.
# =============================================================================

# Helper function to parse boolean environment variables
defmodule ConfigHelpers do
  def get_env_bool(var, default) do
    case System.get_env(var) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      nil -> default
      _ -> default
    end
  end

  def get_env_int(var, default) do
    case System.get_env(var) do
      nil -> default
      val -> String.to_integer(val)
    end
  end

  def parse_kafka_brokers(nil), do: [{~c"localhost", 9092}]
  def parse_kafka_brokers(brokers_string) do
    brokers_string
    |> String.split(",")
    |> Enum.map(fn broker ->
      case String.split(String.trim(broker), ":") do
        [host, port] -> {String.to_charlist(host), String.to_integer(port)}
        [host] -> {String.to_charlist(host), 9092}
      end
    end)
  end
end

# =============================================================================
# Application Configuration
# =============================================================================

# Get the port from environment or default to 4005
port = ConfigHelpers.get_env_int("PORT", 4005)

config :huddle_service,
  port: port,
  namespace: HuddleService

# =============================================================================
# HTTP Endpoint Configuration
# =============================================================================

config :huddle_service, HuddleService.Endpoint,
  http: [port: port],
  url: [
    host: System.get_env("PHX_HOST") || "localhost",
    port: port
  ],
  server: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "default-secret-key-base-change-in-production"

# =============================================================================
# MongoDB Configuration
# =============================================================================

# Support both MONGODB_URL and MONGODB_URI for flexibility
mongodb_url = System.get_env("MONGODB_URL") ||
              System.get_env("MONGODB_URI") ||
              "mongodb://localhost:27017/quckapp_huddles"

config :huddle_service, :mongodb,
  url: mongodb_url,
  pool_size: ConfigHelpers.get_env_int("MONGODB_POOL_SIZE", 10),
  timeout: ConfigHelpers.get_env_int("MONGODB_TIMEOUT", 15000),
  connect_timeout: ConfigHelpers.get_env_int("MONGODB_CONNECT_TIMEOUT", 10000)

# =============================================================================
# Redis Configuration
# =============================================================================

# Support both URL format and individual host/port settings
redis_url = System.get_env("REDIS_URL")
redis_host = System.get_env("REDIS_HOST") || "localhost"
redis_port = ConfigHelpers.get_env_int("REDIS_PORT", 6379)
redis_database = ConfigHelpers.get_env_int("REDIS_DATABASE", 5)
redis_password = System.get_env("REDIS_PASSWORD")

redis_config = if redis_url do
  [url: redis_url]
else
  config = [
    host: redis_host,
    port: redis_port,
    database: redis_database
  ]
  if redis_password, do: Keyword.put(config, :password, redis_password), else: config
end

config :huddle_service, :redis, redis_config

# =============================================================================
# Kafka Configuration
# =============================================================================

kafka_enabled = ConfigHelpers.get_env_bool("KAFKA_ENABLED", false)
kafka_brokers = ConfigHelpers.parse_kafka_brokers(System.get_env("KAFKA_BROKERS"))

config :huddle_service, :kafka,
  enabled: kafka_enabled,
  brokers: kafka_brokers,
  consumer_group: System.get_env("KAFKA_CONSUMER_GROUP") || "huddle-service-group",
  client_id: System.get_env("KAFKA_CLIENT_ID") || "huddle_service"

# Brod (Kafka client) configuration
config :brod,
  clients: [
    huddle_kafka_client: [
      endpoints: kafka_brokers,
      auto_start_producers: true,
      default_producer_config: [
        required_acks: :all,
        ack_timeout: 10_000,
        partition_buffer_limit: 512,
        partition_onwire_limit: 1,
        max_batch_size: 1_048_576,
        max_retries: 3,
        retry_backoff_ms: 500
      ]
    ]
  ]

# =============================================================================
# Authentication Configuration
# =============================================================================

auth_service_url = System.get_env("AUTH_SERVICE_URL") || "http://localhost:8081"
jwt_secret = System.get_env("JWT_SECRET") || "your-secret-key-change-in-production"

config :huddle_service, :auth,
  service_url: auth_service_url,
  verify_ssl: ConfigHelpers.get_env_bool("AUTH_VERIFY_SSL", true)

config :huddle_service, HuddleService.Guardian,
  issuer: System.get_env("JWT_ISSUER") || "quckapp",
  secret_key: jwt_secret,
  ttl: {ConfigHelpers.get_env_int("JWT_TTL_HOURS", 24), :hours}

# =============================================================================
# Logging Configuration
# =============================================================================

log_level = case System.get_env("LOG_LEVEL") do
  "debug" -> :debug
  "info" -> :info
  "warning" -> :warning
  "warn" -> :warning
  "error" -> :error
  _ -> if config_env() == :prod, do: :info, else: :debug
end

config :logger, level: log_level

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :huddle_id, :user_id, :channel_id]

# =============================================================================
# Production-specific Configuration
# =============================================================================

if config_env() == :prod do
  # In production, require SECRET_KEY_BASE
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :huddle_service, HuddleService.Endpoint,
    secret_key_base: secret_key_base

  # Require JWT_SECRET in production
  if System.get_env("JWT_SECRET") == nil do
    raise """
    environment variable JWT_SECRET is missing.
    Please set a secure JWT secret for production.
    """
  end
end

# =============================================================================
# Telemetry Configuration
# =============================================================================

config :huddle_service, :telemetry,
  enabled: ConfigHelpers.get_env_bool("TELEMETRY_ENABLED", true)

# =============================================================================
# Distributed Erlang Configuration (for clustering)
# =============================================================================

if System.get_env("RELEASE_NODE") do
  config :huddle_service,
    release_node: System.get_env("RELEASE_NODE")
end

# =============================================================================
# Feature Flags
# =============================================================================

config :huddle_service, :features,
  max_participants_per_huddle: ConfigHelpers.get_env_int("MAX_PARTICIPANTS_PER_HUDDLE", 50),
  huddle_timeout_minutes: ConfigHelpers.get_env_int("HUDDLE_TIMEOUT_MINUTES", 60),
  enable_recording: ConfigHelpers.get_env_bool("ENABLE_RECORDING", false)
