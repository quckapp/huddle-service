import Config

config :huddle_service, namespace: HuddleService

config :huddle_service, HuddleService.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [json: HuddleService.ErrorJSON], layout: false],
  pubsub_server: HuddleService.PubSub

config :huddle_service, :mongodb,
  url: System.get_env("MONGODB_URI") || "mongodb://localhost:27017/quckapp_huddles",
  pool_size: 10

config :huddle_service, :redis,
  host: System.get_env("REDIS_HOST") || "localhost",
  port: String.to_integer(System.get_env("REDIS_PORT") || "6379"),
  database: 5

config :huddle_service, :kafka,
  enabled: false,
  brokers: [{~c"localhost", 9092}],
  consumer_group: "huddle-service-group"

config :huddle_service, HuddleService.Guardian,
  issuer: "quckapp",
  secret_key: System.get_env("JWT_SECRET") || "your-secret-key"

config :logger, :console, format: "$time $metadata[$level] $message\n", metadata: [:request_id, :huddle_id]
config :phoenix, :json_library, Jason

# Import environment-specific config
# Environments: dev, test, local, qa, uat1, uat2, uat3, staging, production, live, prod
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
