import Config

# Send all logs to stderr so they don't corrupt the MCP STDIO transport on stdout
config :logger, :default_handler,
  config: %{type: :standard_error}
