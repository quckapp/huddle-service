defmodule HuddleService.Kafka.Producer do
  @moduledoc """
  Kafka producer for huddle events
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def publish(topic, message) do
    GenServer.cast(__MODULE__, {:publish, topic, message})
  end

  @impl true
  def init(_) do
    brokers = System.get_env("KAFKA_BROKERS", "localhost:9092")
    |> String.split(",")
    |> Enum.map(fn broker ->
      [host, port] = String.split(broker, ":")
      {String.to_charlist(host), String.to_integer(port)}
    end)

    :brod.start_client(brokers, :huddle_kafka_client, [])
    :brod.start_producer(:huddle_kafka_client, "huddle.events", [])

    {:ok, %{client: :huddle_kafka_client}}
  end

  @impl true
  def handle_cast({:publish, topic, message}, state) do
    key = Map.get(message, "huddle_id", "")
    value = Jason.encode!(message)

    case :brod.produce_sync(state.client, topic, :hash, key, value) do
      :ok ->
        Logger.debug("Published message to #{topic}")
      {:error, reason} ->
        Logger.error("Failed to publish to #{topic}: #{inspect(reason)}")
    end

    {:noreply, state}
  end
end
