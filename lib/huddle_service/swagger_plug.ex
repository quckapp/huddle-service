defmodule HuddleService.SwaggerPlug do
  @moduledoc """
  Plug for serving Swagger UI and OpenAPI specification.

  This plug provides:
  - GET /swagger - Swagger UI HTML interface
  - GET /api/v1/openapi - OpenAPI JSON specification
  """
  import Plug.Conn

  @swagger_ui_version "5.11.0"

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["swagger"]} = conn, _opts) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, swagger_ui_html())
    |> halt()
  end

  def call(%Plug.Conn{path_info: ["api", "openapi"]} = conn, _opts) do
    spec = HuddleService.ApiSpec.spec()
    json = Jason.encode!(spec)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
    |> halt()
  end

  def call(conn, _opts) do
    conn
  end

  defp swagger_ui_html do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Huddle Service API - Swagger UI</title>
      <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/swagger-ui.css" />
      <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/favicon-32x32.png" sizes="32x32" />
      <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/favicon-16x16.png" sizes="16x16" />
      <style>
        html {
          box-sizing: border-box;
          overflow: -moz-scrollbars-vertical;
          overflow-y: scroll;
        }
        *,
        *:before,
        *:after {
          box-sizing: inherit;
        }
        body {
          margin: 0;
          background: #fafafa;
        }
        .topbar {
          display: none;
        }
        .swagger-ui .info .title {
          color: #3b4151;
        }
        .swagger-ui .info .description p {
          color: #3b4151;
        }
      </style>
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/swagger-ui-bundle.js" charset="UTF-8"></script>
      <script src="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/swagger-ui-standalone-preset.js" charset="UTF-8"></script>
      <script>
        window.onload = function() {
          const ui = SwaggerUIBundle({
            url: "/api/v1/openapi",
            dom_id: '#swagger-ui',
            deepLinking: true,
            presets: [
              SwaggerUIBundle.presets.apis,
              SwaggerUIStandalonePreset
            ],
            plugins: [
              SwaggerUIBundle.plugins.DownloadUrl
            ],
            layout: "StandaloneLayout",
            validatorUrl: null,
            supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch'],
            defaultModelsExpandDepth: 1,
            defaultModelExpandDepth: 1,
            displayRequestDuration: true,
            filter: true,
            showExtensions: true,
            showCommonExtensions: true,
            tryItOutEnabled: true
          });
          window.ui = ui;
        };
      </script>
    </body>
    </html>
    """
  end
end
