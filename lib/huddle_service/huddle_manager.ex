defmodule HuddleService.HuddleManager do
  @moduledoc """
  Manages huddle (audio room) lifecycle and participants
  """
  use GenServer
  require Logger

  @collection "huddles"
  @max_participants 50

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_huddle(params) do
    huddle = %{
      "_id" => generate_id(),
      "channel_id" => params["channel_id"],
      "workspace_id" => params["workspace_id"],
      "title" => params["title"] || "Huddle",
      "created_by" => params["created_by"],
      "participants" => [params["created_by"]],
      "max_participants" => params["max_participants"] || @max_participants,
      "status" => "active",
      "settings" => %{
        "mute_on_join" => params["mute_on_join"] || false,
        "allow_screen_share" => params["allow_screen_share"] || true,
        "recording_enabled" => params["recording_enabled"] || false
      },
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case Mongo.insert_one(:mongo, @collection, huddle) do
      {:ok, _} ->
        publish_event("huddle.created", huddle)
        cache_huddle(huddle)
        {:ok, huddle}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Create huddle with explicit ID (from Kafka events)"
  def create_huddle(huddle_id, params) do
    huddle = %{
      "_id" => huddle_id,
      "channel_id" => params[:channel_id] || params["channel_id"],
      "workspace_id" => params[:workspace_id] || params["workspace_id"],
      "title" => params[:name] || params["name"] || "Huddle",
      "created_by" => params[:creator_id] || params["creator_id"],
      "participants" => [params[:creator_id] || params["creator_id"]],
      "max_participants" => @max_participants,
      "status" => "active",
      "type" => params[:type] || params["type"] || "audio",
      "settings" => %{
        "mute_on_join" => false,
        "allow_screen_share" => true,
        "recording_enabled" => false
      },
      "metadata" => params[:metadata] || params["metadata"] || %{},
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case Mongo.insert_one(:mongo, @collection, huddle) do
      {:ok, _} ->
        publish_event("huddle.created", huddle)
        cache_huddle(huddle)
        {:ok, huddle}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_huddle(huddle_id) do
    case get_cached_huddle(huddle_id) do
      nil ->
        case Mongo.find_one(:mongo, @collection, %{"_id" => huddle_id}) do
          nil -> {:error, :not_found}
          huddle ->
            cache_huddle(huddle)
            {:ok, huddle}
        end
      huddle ->
        {:ok, huddle}
    end
  end

  def list_channel_huddles(channel_id) do
    Mongo.find(:mongo, @collection, %{
      "channel_id" => channel_id,
      "status" => "active"
    })
    |> Enum.to_list()
  end

  def join_huddle(huddle_id, user_id) do
    join_huddle(huddle_id, user_id, %{})
  end

  @doc "Join a huddle with metadata"
  def join_huddle(huddle_id, user_id, metadata) do
    case get_huddle(huddle_id) do
      {:ok, huddle} ->
        if length(huddle["participants"]) >= huddle["max_participants"] do
          {:error, "Huddle is full"}
        else
          if user_id in huddle["participants"] do
            {:ok, huddle}
          else
            updated_participants = huddle["participants"] ++ [user_id]
            update_huddle(huddle_id, %{
              "participants" => updated_participants,
              "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
            })
            updated_huddle = Map.put(huddle, "participants", updated_participants)
            publish_event("huddle.participant_joined", %{
              "huddle_id" => huddle_id,
              "user_id" => user_id,
              "participant_count" => length(updated_participants),
              "metadata" => metadata
            })
            cache_huddle(updated_huddle)
            {:ok, updated_huddle}
          end
        end
      error -> error
    end
  end

  def leave_huddle(huddle_id, user_id) do
    case get_huddle(huddle_id) do
      {:ok, huddle} ->
        updated_participants = Enum.reject(huddle["participants"], &(&1 == user_id))

        if Enum.empty?(updated_participants) do
          end_huddle(huddle_id)
          {:ok, Map.put(huddle, "status", "ended")}
        else
          update_huddle(huddle_id, %{
            "participants" => updated_participants,
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          })
          updated_huddle = Map.put(huddle, "participants", updated_participants)
          publish_event("huddle.participant_left", %{
            "huddle_id" => huddle_id,
            "user_id" => user_id,
            "participant_count" => length(updated_participants)
          })
          cache_huddle(updated_huddle)
          {:ok, updated_huddle}
        end
      error -> error
    end
  end

  def end_huddle(huddle_id) do
    end_huddle(huddle_id, "normal")
  end

  @doc "End a huddle with reason"
  def end_huddle(huddle_id, reason) do
    case Mongo.update_one(:mongo, @collection,
      %{"_id" => huddle_id},
      %{"$set" => %{
        "status" => "ended",
        "end_reason" => reason,
        "ended_at" => DateTime.utc_now() |> DateTime.to_iso8601()
      }}
    ) do
      {:ok, _} ->
        publish_event("huddle.ended", %{"huddle_id" => huddle_id, "reason" => reason})
        clear_cached_huddle(huddle_id)
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Handle user actions in huddle (mute, unmute, etc.)"
  def user_action(huddle_id, user_id, action) do
    case get_huddle(huddle_id) do
      {:ok, huddle} ->
        if user_id in huddle["participants"] do
          publish_event("huddle.user_action", %{
            "huddle_id" => huddle_id,
            "user_id" => user_id,
            "action" => action,
            "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
          })
          {:ok, :action_recorded}
        else
          {:error, :not_participant}
        end
      error -> error
    end
  end

  @doc "Handle user disconnect - remove from all active huddles"
  def handle_user_disconnect(user_id) do
    # Find all active huddles the user is in
    huddles = Mongo.find(:mongo, @collection, %{
      "status" => "active",
      "participants" => user_id
    }) |> Enum.to_list()

    Enum.each(huddles, fn huddle ->
      leave_huddle(huddle["_id"], user_id)
    end)

    {:ok, length(huddles)}
  end

  @doc "Get active huddle for a conversation/channel"
  def get_conversation_huddle(conversation_id) do
    case Mongo.find_one(:mongo, @collection, %{
      "channel_id" => conversation_id,
      "status" => "active"
    }) do
      nil -> {:error, :not_found}
      huddle ->
        cache_huddle(huddle)
        {:ok, huddle}
    end
  end

  # Private functions

  defp update_huddle(huddle_id, updates) do
    Mongo.update_one(:mongo, @collection,
      %{"_id" => huddle_id},
      %{"$set" => updates}
    )
  end

  defp generate_id do
    :crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower)
  end

  defp cache_huddle(huddle) do
    key = "huddle:#{huddle["_id"]}"
    Redix.command(:redix, ["SETEX", key, "3600", Jason.encode!(huddle)])
  end

  defp get_cached_huddle(huddle_id) do
    key = "huddle:#{huddle_id}"
    case Redix.command(:redix, ["GET", key]) do
      {:ok, nil} -> nil
      {:ok, data} -> Jason.decode!(data)
      _ -> nil
    end
  end

  defp clear_cached_huddle(huddle_id) do
    key = "huddle:#{huddle_id}"
    Redix.command(:redix, ["DEL", key])
  end

  defp publish_event(event_type, data) do
    HuddleService.Kafka.Producer.publish("huddle.events", %{
      "type" => event_type,
      "data" => data,
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
end
