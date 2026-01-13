defmodule HuddleService.Router do
  @moduledoc """
  HTTP Router for Huddle Service
  """
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  # Health endpoints
  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "healthy", service: "huddle-service"}))
  end

  get "/health/ready" do
    checks = %{
      mongo: check_mongo(),
      redis: check_redis()
    }
    status = if Enum.all?(Map.values(checks), &(&1 == "ok")), do: 200, else: 503
    send_resp(conn, status, Jason.encode!(%{ready: status == 200, checks: checks}))
  end

  get "/health/live" do
    send_resp(conn, 200, Jason.encode!(%{live: true}))
  end

  # Huddle endpoints
  post "/api/v1/huddles" do
    case HuddleService.HuddleManager.create_huddle(conn.body_params) do
      {:ok, huddle} -> send_resp(conn, 201, Jason.encode!(%{success: true, data: huddle}))
      {:error, reason} -> send_resp(conn, 400, Jason.encode!(%{success: false, error: reason}))
    end
  end

  get "/api/v1/huddles/:huddle_id" do
    case HuddleService.HuddleManager.get_huddle(huddle_id) do
      {:ok, huddle} -> send_resp(conn, 200, Jason.encode!(%{success: true, data: huddle}))
      {:error, :not_found} -> send_resp(conn, 404, Jason.encode!(%{success: false, error: "Huddle not found"}))
    end
  end

  get "/api/v1/huddles/channel/:channel_id" do
    huddles = HuddleService.HuddleManager.list_channel_huddles(channel_id)
    send_resp(conn, 200, Jason.encode!(%{success: true, data: huddles}))
  end

  post "/api/v1/huddles/:huddle_id/join" do
    user_id = conn.body_params["user_id"]
    case HuddleService.HuddleManager.join_huddle(huddle_id, user_id) do
      {:ok, huddle} -> send_resp(conn, 200, Jason.encode!(%{success: true, data: huddle}))
      {:error, reason} -> send_resp(conn, 400, Jason.encode!(%{success: false, error: reason}))
    end
  end

  post "/api/v1/huddles/:huddle_id/leave" do
    user_id = conn.body_params["user_id"]
    case HuddleService.HuddleManager.leave_huddle(huddle_id, user_id) do
      {:ok, huddle} -> send_resp(conn, 200, Jason.encode!(%{success: true, data: huddle}))
      {:error, reason} -> send_resp(conn, 400, Jason.encode!(%{success: false, error: reason}))
    end
  end

  delete "/api/v1/huddles/:huddle_id" do
    case HuddleService.HuddleManager.end_huddle(huddle_id) do
      :ok -> send_resp(conn, 200, Jason.encode!(%{success: true}))
      {:error, reason} -> send_resp(conn, 400, Jason.encode!(%{success: false, error: reason}))
    end
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end

  defp check_mongo do
    case Mongo.command(:mongo, %{ping: 1}) do
      {:ok, _} -> "ok"
      _ -> "error"
    end
  end

  defp check_redis do
    case Redix.command(:redix, ["PING"]) do
      {:ok, "PONG"} -> "ok"
      _ -> "error"
    end
  end
end
