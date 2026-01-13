defmodule HuddleService.MixProject do
  use Mix.Project

  def project do
    [
      app: :huddle_service,
      version: "1.0.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HuddleService.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:mongodb_driver, "~> 1.2"},
      {:redix, "~> 1.2"},
      {:brod, "~> 3.16"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end
end
