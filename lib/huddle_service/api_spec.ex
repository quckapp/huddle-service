defmodule HuddleService.ApiSpec do
  @moduledoc """
  OpenAPI specification for Huddle Service API
  """
  alias OpenApiSpex.{Info, OpenApi, Paths, Server, Components, SecurityScheme}
  alias HuddleService.Schemas.{Common, Huddle}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Huddle Service API",
        description: "Audio/video huddle room management API",
        version: "1.0.0"
      },
      servers: [
        %Server{url: "/", description: "Current server"}
      ],
      paths: paths(),
      components: %Components{
        securitySchemes: %{
          "bearerAuth" => %SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
            description: "JWT Bearer token authentication"
          },
          "apiKey" => %SecurityScheme{
            type: "apiKey",
            name: "X-API-Key",
            in: "header",
            description: "API Key authentication"
          }
        },
        schemas: schemas()
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end

  defp paths do
    %{
      "/health" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["Health"],
          summary: "Health check",
          description: "Basic health check endpoint",
          operationId: "getHealth",
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Service is healthy",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.HealthResponse
                }
              }
            }
          }
        }
      },
      "/health/ready" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["Health"],
          summary: "Readiness check",
          description: "Check if service is ready to accept traffic (MongoDB, Redis connected)",
          operationId: "getHealthReady",
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Service is ready",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ReadinessResponse
                }
              }
            },
            503 => %OpenApiSpex.Response{
              description: "Service is not ready",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ReadinessResponse
                }
              }
            }
          }
        }
      },
      "/health/live" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["Health"],
          summary: "Liveness check",
          description: "Check if service is alive",
          operationId: "getHealthLive",
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Service is alive",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.LivenessResponse
                }
              }
            }
          }
        }
      },
      "/api/v1/huddles" => %OpenApiSpex.PathItem{
        post: %OpenApiSpex.Operation{
          tags: ["Huddles"],
          summary: "Create huddle",
          description: "Create a new audio/video huddle room",
          operationId: "createHuddle",
          security: [%{"bearerAuth" => []}, %{"apiKey" => []}],
          requestBody: %OpenApiSpex.RequestBody{
            description: "Huddle creation parameters",
            required: true,
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: Huddle.CreateHuddleRequest
              }
            }
          },
          responses: %{
            201 => %OpenApiSpex.Response{
              description: "Huddle created successfully",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Huddle.HuddleSuccessResponse
                }
              }
            },
            400 => %OpenApiSpex.Response{
              description: "Invalid request parameters",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            },
            401 => %OpenApiSpex.Response{
              description: "Unauthorized",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            }
          }
        }
      },
      "/api/v1/huddles/{huddle_id}" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["Huddles"],
          summary: "Get huddle",
          description: "Retrieve huddle details by ID",
          operationId: "getHuddle",
          security: [%{"bearerAuth" => []}, %{"apiKey" => []}],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :huddle_id,
              in: :path,
              required: true,
              description: "The unique identifier of the huddle",
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Huddle found",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Huddle.HuddleSuccessResponse
                }
              }
            },
            404 => %OpenApiSpex.Response{
              description: "Huddle not found",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            }
          }
        },
        delete: %OpenApiSpex.Operation{
          tags: ["Huddles"],
          summary: "End huddle",
          description: "End/terminate an active huddle",
          operationId: "endHuddle",
          security: [%{"bearerAuth" => []}, %{"apiKey" => []}],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :huddle_id,
              in: :path,
              required: true,
              description: "The unique identifier of the huddle",
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Huddle ended successfully",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.SuccessResponse
                }
              }
            },
            400 => %OpenApiSpex.Response{
              description: "Failed to end huddle",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            },
            404 => %OpenApiSpex.Response{
              description: "Huddle not found",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            }
          }
        }
      },
      "/api/v1/huddles/channel/{channel_id}" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["Huddles"],
          summary: "List channel huddles",
          description: "List all active huddles in a channel",
          operationId: "listChannelHuddles",
          security: [%{"bearerAuth" => []}, %{"apiKey" => []}],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :channel_id,
              in: :path,
              required: true,
              description: "The unique identifier of the channel",
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "List of huddles in the channel",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Huddle.HuddleListResponse
                }
              }
            }
          }
        }
      },
      "/api/v1/huddles/{huddle_id}/join" => %OpenApiSpex.PathItem{
        post: %OpenApiSpex.Operation{
          tags: ["Huddles"],
          summary: "Join huddle",
          description: "Join an existing huddle as a participant",
          operationId: "joinHuddle",
          security: [%{"bearerAuth" => []}, %{"apiKey" => []}],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :huddle_id,
              in: :path,
              required: true,
              description: "The unique identifier of the huddle",
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          requestBody: %OpenApiSpex.RequestBody{
            description: "Join request parameters",
            required: true,
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: Huddle.JoinHuddleRequest
              }
            }
          },
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Successfully joined huddle",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Huddle.HuddleSuccessResponse
                }
              }
            },
            400 => %OpenApiSpex.Response{
              description: "Failed to join huddle (e.g., huddle is full)",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            },
            404 => %OpenApiSpex.Response{
              description: "Huddle not found",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            }
          }
        }
      },
      "/api/v1/huddles/{huddle_id}/leave" => %OpenApiSpex.PathItem{
        post: %OpenApiSpex.Operation{
          tags: ["Huddles"],
          summary: "Leave huddle",
          description: "Leave an active huddle",
          operationId: "leaveHuddle",
          security: [%{"bearerAuth" => []}, %{"apiKey" => []}],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :huddle_id,
              in: :path,
              required: true,
              description: "The unique identifier of the huddle",
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          requestBody: %OpenApiSpex.RequestBody{
            description: "Leave request parameters",
            required: true,
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: Huddle.LeaveHuddleRequest
              }
            }
          },
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Successfully left huddle",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Huddle.HuddleSuccessResponse
                }
              }
            },
            400 => %OpenApiSpex.Response{
              description: "Failed to leave huddle",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            },
            404 => %OpenApiSpex.Response{
              description: "Huddle not found",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: Common.ErrorResponse
                }
              }
            }
          }
        }
      }
    }
  end

  defp schemas do
    %{
      "HealthResponse" => Common.HealthResponse.schema(),
      "ReadinessResponse" => Common.ReadinessResponse.schema(),
      "LivenessResponse" => Common.LivenessResponse.schema(),
      "SuccessResponse" => Common.SuccessResponse.schema(),
      "ErrorResponse" => Common.ErrorResponse.schema(),
      "CreateHuddleRequest" => Huddle.CreateHuddleRequest.schema(),
      "HuddleResponse" => Huddle.HuddleResponse.schema(),
      "HuddleSuccessResponse" => Huddle.HuddleSuccessResponse.schema(),
      "HuddleListResponse" => Huddle.HuddleListResponse.schema(),
      "JoinHuddleRequest" => Huddle.JoinHuddleRequest.schema(),
      "LeaveHuddleRequest" => Huddle.LeaveHuddleRequest.schema(),
      "ParticipantInfo" => Huddle.ParticipantInfo.schema(),
      "HuddleSettings" => Huddle.HuddleSettings.schema()
    }
  end
end
