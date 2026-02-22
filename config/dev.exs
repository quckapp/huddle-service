import Config

# MongoDB configuration for development
config :huddle_service, :mongodb,
  url: "mongodb://localhost:27017/quckapp_huddles_dev",
  pool_size: 5

# Redis configuration for development
config :huddle_service, :redis,
  host: "localhost",
  port: 6379,
  database: 2

# Kafka configuration for development (disabled by default)
config :huddle_service, :kafka,
  enabled: false,
  brokers: [{~c"localhost", 9092}],
  consumer_group: "huddle-service-group-dev"

# Guardian JWT configuration for development
config :huddle_service, HuddleService.Guardian,
  issuer: "huddle_service",
  secret_key: "dev_jwt_secret_for_huddle_service"

config :logger, level: :debug
