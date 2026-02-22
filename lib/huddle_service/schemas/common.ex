defmodule HuddleService.Schemas.Common do
  @moduledoc """
  Common schema definitions for Huddle Service API responses
  """
  alias OpenApiSpex.Schema
  require OpenApiSpex

  defmodule HealthResponse do
    @moduledoc """
    Health check response schema
    """
    OpenApiSpex.schema(%{
      title: "HealthResponse",
      description: "Health check response",
      type: :object,
      required: [:status, :service],
      properties: %{
        status: %Schema{type: :string, description: "Health status", example: "healthy"},
        service: %Schema{type: :string, description: "Service name", example: "huddle-service"}
      },
      example: %{
        status: "healthy",
        service: "huddle-service"
      }
    })
  end

  defmodule ReadinessChecks do
    @moduledoc """
    Readiness checks detail schema
    """
    OpenApiSpex.schema(%{
      title: "ReadinessChecks",
      description: "Individual service dependency checks",
      type: :object,
      properties: %{
        mongo: %Schema{type: :string, description: "MongoDB connection status", enum: ["ok", "error"]},
        redis: %Schema{type: :string, description: "Redis connection status", enum: ["ok", "error"]}
      },
      example: %{
        mongo: "ok",
        redis: "ok"
      }
    })
  end

  defmodule ReadinessResponse do
    @moduledoc """
    Readiness check response schema
    """
    OpenApiSpex.schema(%{
      title: "ReadinessResponse",
      description: "Readiness check response with dependency status",
      type: :object,
      required: [:ready, :checks],
      properties: %{
        ready: %Schema{type: :boolean, description: "Overall readiness status"},
        checks: ReadinessChecks
      },
      example: %{
        ready: true,
        checks: %{
          mongo: "ok",
          redis: "ok"
        }
      }
    })
  end

  defmodule LivenessResponse do
    @moduledoc """
    Liveness check response schema
    """
    OpenApiSpex.schema(%{
      title: "LivenessResponse",
      description: "Liveness check response",
      type: :object,
      required: [:live],
      properties: %{
        live: %Schema{type: :boolean, description: "Whether the service is alive"}
      },
      example: %{
        live: true
      }
    })
  end

  defmodule SuccessResponse do
    @moduledoc """
    Generic success response schema
    """
    OpenApiSpex.schema(%{
      title: "SuccessResponse",
      description: "Generic success response",
      type: :object,
      required: [:success],
      properties: %{
        success: %Schema{type: :boolean, description: "Operation success status"}
      },
      example: %{
        success: true
      }
    })
  end

  defmodule ErrorResponse do
    @moduledoc """
    Error response schema
    """
    OpenApiSpex.schema(%{
      title: "ErrorResponse",
      description: "Error response",
      type: :object,
      required: [:success, :error],
      properties: %{
        success: %Schema{type: :boolean, description: "Operation success status (always false)", example: false},
        error: %Schema{type: :string, description: "Error message describing what went wrong"}
      },
      example: %{
        success: false,
        error: "Invalid request parameters"
      }
    })
  end
end
