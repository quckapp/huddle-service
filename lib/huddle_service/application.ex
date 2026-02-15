defmodule HuddleService.Application do
  @moduledoc """
  HuddleService Application - Audio rooms for real-time collaboration
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Initialize circuit breakers
    HuddleService.CircuitBreaker.init()

    children = [
      # MongoDB connection
      {Mongo, [
        name: :mongo,
        url: System.get_env("MONGODB_URL", "mongodb://localhost:27017/quckapp_huddles"),
        pool_size: 10
      ]},
      # Redis connection
      {Redix, [
        name: :redix,
        host: System.get_env("REDIS_HOST", "localhost"),
        port: String.to_integer(System.get_env("REDIS_PORT", "6379")),
        password: System.get_env("REDIS_PASSWORD")
      ]},
      # PubSub for Phoenix Channels
      {Phoenix.PubSub, name: HuddleService.PubSub},
      # Huddle Registry
      {Registry, keys: :unique, name: HuddleService.HuddleRegistry},
      # Huddle Supervisor
      {DynamicSupervisor, name: HuddleService.HuddleSupervisor, strategy: :one_for_one},
      # Kafka Producer & Consumer
      HuddleService.Kafka.Producer,
      HuddleService.Kafka.Consumer,
      # HTTP Endpoint
      {Plug.Cowboy, scheme: :http, plug: HuddleService.Router, options: [port: port()]}
    ]

    opts = [strategy: :one_for_one, name: HuddleService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port do
    String.to_integer(System.get_env("PORT", "4005"))
  end
end
