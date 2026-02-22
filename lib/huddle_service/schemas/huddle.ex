defmodule HuddleService.Schemas.Huddle do
  @moduledoc """
  Huddle-related schema definitions for the API
  """
  alias OpenApiSpex.Schema
  require OpenApiSpex

  defmodule HuddleSettings do
    @moduledoc """
    Huddle settings/configuration schema
    """
    OpenApiSpex.schema(%{
      title: "HuddleSettings",
      description: "Huddle room settings and configuration",
      type: :object,
      properties: %{
        mute_on_join: %Schema{
          type: :boolean,
          description: "Whether participants are muted when joining",
          default: false
        },
        allow_screen_share: %Schema{
          type: :boolean,
          description: "Whether screen sharing is allowed",
          default: true
        },
        recording_enabled: %Schema{
          type: :boolean,
          description: "Whether recording is enabled for this huddle",
          default: false
        }
      },
      example: %{
        mute_on_join: false,
        allow_screen_share: true,
        recording_enabled: false
      }
    })
  end

  defmodule ParticipantInfo do
    @moduledoc """
    Participant information schema
    """
    OpenApiSpex.schema(%{
      title: "ParticipantInfo",
      description: "Information about a huddle participant",
      type: :object,
      required: [:user_id],
      properties: %{
        user_id: %Schema{type: :string, description: "Unique identifier of the participant"},
        joined_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "ISO 8601 timestamp when the user joined"
        },
        is_muted: %Schema{type: :boolean, description: "Whether the participant is muted", default: false},
        is_video_on: %Schema{type: :boolean, description: "Whether the participant's video is on", default: false}
      },
      example: %{
        user_id: "user_abc123",
        joined_at: "2024-01-15T10:30:00Z",
        is_muted: false,
        is_video_on: true
      }
    })
  end

  defmodule CreateHuddleRequest do
    @moduledoc """
    Request schema for creating a new huddle
    """
    OpenApiSpex.schema(%{
      title: "CreateHuddleRequest",
      description: "Request body for creating a new huddle",
      type: :object,
      required: [:channel_id, :created_by],
      properties: %{
        channel_id: %Schema{
          type: :string,
          description: "ID of the channel where the huddle will be created"
        },
        workspace_id: %Schema{
          type: :string,
          description: "ID of the workspace"
        },
        title: %Schema{
          type: :string,
          description: "Title/name of the huddle",
          default: "Huddle",
          maxLength: 100
        },
        created_by: %Schema{
          type: :string,
          description: "User ID of the huddle creator"
        },
        max_participants: %Schema{
          type: :integer,
          description: "Maximum number of participants allowed",
          default: 50,
          minimum: 2,
          maximum: 100
        },
        mute_on_join: %Schema{
          type: :boolean,
          description: "Whether to mute participants on join",
          default: false
        },
        allow_screen_share: %Schema{
          type: :boolean,
          description: "Whether to allow screen sharing",
          default: true
        },
        recording_enabled: %Schema{
          type: :boolean,
          description: "Whether to enable recording",
          default: false
        }
      },
      example: %{
        channel_id: "ch_xyz789",
        workspace_id: "ws_abc123",
        title: "Quick standup",
        created_by: "user_def456",
        max_participants: 10,
        mute_on_join: false,
        allow_screen_share: true,
        recording_enabled: false
      }
    })
  end

  defmodule HuddleResponse do
    @moduledoc """
    Huddle data response schema
    """
    OpenApiSpex.schema(%{
      title: "HuddleResponse",
      description: "Huddle room data",
      type: :object,
      required: [:_id, :channel_id, :status, :created_at],
      properties: %{
        _id: %Schema{type: :string, description: "Unique huddle identifier"},
        channel_id: %Schema{type: :string, description: "Channel where the huddle is hosted"},
        workspace_id: %Schema{type: :string, description: "Workspace identifier"},
        title: %Schema{type: :string, description: "Huddle title/name"},
        created_by: %Schema{type: :string, description: "User ID who created the huddle"},
        participants: %Schema{
          type: :array,
          items: %Schema{type: :string},
          description: "List of participant user IDs"
        },
        max_participants: %Schema{
          type: :integer,
          description: "Maximum number of participants allowed"
        },
        status: %Schema{
          type: :string,
          description: "Current huddle status",
          enum: ["active", "ended"]
        },
        settings: HuddleSettings,
        created_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "ISO 8601 timestamp when the huddle was created"
        },
        updated_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "ISO 8601 timestamp when the huddle was last updated"
        },
        ended_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "ISO 8601 timestamp when the huddle ended (if ended)"
        }
      },
      example: %{
        _id: "abc123def456",
        channel_id: "ch_xyz789",
        workspace_id: "ws_abc123",
        title: "Quick standup",
        created_by: "user_def456",
        participants: ["user_def456", "user_ghi789"],
        max_participants: 50,
        status: "active",
        settings: %{
          mute_on_join: false,
          allow_screen_share: true,
          recording_enabled: false
        },
        created_at: "2024-01-15T10:30:00Z",
        updated_at: "2024-01-15T10:35:00Z"
      }
    })
  end

  defmodule HuddleSuccessResponse do
    @moduledoc """
    Success response containing huddle data
    """
    OpenApiSpex.schema(%{
      title: "HuddleSuccessResponse",
      description: "Successful huddle operation response",
      type: :object,
      required: [:success, :data],
      properties: %{
        success: %Schema{type: :boolean, description: "Operation success status"},
        data: HuddleResponse
      },
      example: %{
        success: true,
        data: %{
          _id: "abc123def456",
          channel_id: "ch_xyz789",
          workspace_id: "ws_abc123",
          title: "Quick standup",
          created_by: "user_def456",
          participants: ["user_def456"],
          max_participants: 50,
          status: "active",
          settings: %{
            mute_on_join: false,
            allow_screen_share: true,
            recording_enabled: false
          },
          created_at: "2024-01-15T10:30:00Z",
          updated_at: "2024-01-15T10:30:00Z"
        }
      }
    })
  end

  defmodule HuddleListResponse do
    @moduledoc """
    Response schema for listing huddles
    """
    OpenApiSpex.schema(%{
      title: "HuddleListResponse",
      description: "List of huddles response",
      type: :object,
      required: [:success, :data],
      properties: %{
        success: %Schema{type: :boolean, description: "Operation success status"},
        data: %Schema{
          type: :array,
          items: HuddleResponse,
          description: "Array of huddle objects"
        }
      },
      example: %{
        success: true,
        data: [
          %{
            _id: "abc123def456",
            channel_id: "ch_xyz789",
            workspace_id: "ws_abc123",
            title: "Quick standup",
            created_by: "user_def456",
            participants: ["user_def456", "user_ghi789"],
            max_participants: 50,
            status: "active",
            settings: %{
              mute_on_join: false,
              allow_screen_share: true,
              recording_enabled: false
            },
            created_at: "2024-01-15T10:30:00Z",
            updated_at: "2024-01-15T10:35:00Z"
          }
        ]
      }
    })
  end

  defmodule JoinHuddleRequest do
    @moduledoc """
    Request schema for joining a huddle
    """
    OpenApiSpex.schema(%{
      title: "JoinHuddleRequest",
      description: "Request body for joining a huddle",
      type: :object,
      required: [:user_id],
      properties: %{
        user_id: %Schema{
          type: :string,
          description: "ID of the user joining the huddle"
        }
      },
      example: %{
        user_id: "user_ghi789"
      }
    })
  end

  defmodule LeaveHuddleRequest do
    @moduledoc """
    Request schema for leaving a huddle
    """
    OpenApiSpex.schema(%{
      title: "LeaveHuddleRequest",
      description: "Request body for leaving a huddle",
      type: :object,
      required: [:user_id],
      properties: %{
        user_id: %Schema{
          type: :string,
          description: "ID of the user leaving the huddle"
        }
      },
      example: %{
        user_id: "user_ghi789"
      }
    })
  end
end
