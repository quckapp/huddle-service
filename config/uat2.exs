# =============================================================================
# UAT2 Environment Configuration
# =============================================================================
# Use this profile for UAT2 environment
# Run with: MIX_ENV=uat2 mix phx.server
# =============================================================================

import Config

config :huddle_service, HuddleService.Endpoint,
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4005")],
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 443, scheme: "https"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

# MongoDB - UAT2
config :huddle_service, :mongodb,
  url: System.get_env("MONGODB_URI"),
  pool_size: String.to_integer(System.get_env("MONGODB_POOL_SIZE") || "15")

# Redis - UAT2
config :huddle_service, :redis,
  host: System.get_env("REDIS_HOST"),
  port: String.to_integer(System.get_env("REDIS_PORT") || "6379"),
  password: System.get_env("REDIS_PASSWORD"),
  database: String.to_integer(System.get_env("REDIS_DATABASE") || "5")

# Kafka - UAT2
config :huddle_service, :kafka,
  brokers: [System.get_env("KAFKA_BROKER") || "localhost:9092"],
  consumer_group: "huddle-service-uat2"

# JWT
config :huddle_service, HuddleService.Guardian,
  issuer: "quckapp-auth",
  secret_key: System.get_env("JWT_SECRET")

# Services
config :huddle_service, :services,
  auth_service_url: System.get_env("AUTH_SERVICE_URL"),
  user_service_url: System.get_env("USER_SERVICE_URL"),
  channel_service_url: System.get_env("CHANNEL_SERVICE_URL")

# Logging
config :logger, level: :info
