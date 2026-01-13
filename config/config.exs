import Config

config :huddle_service,
  port: String.to_integer(System.get_env("PORT") || "4005")

config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n"

import_config "#{config_env()}.exs"
