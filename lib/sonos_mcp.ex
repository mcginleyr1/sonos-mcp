defmodule SonosMcp do
  use Application

  def start(_type, _args) do
    EMCP.SessionStore.ETS.init()

    children = [
      SonosMcp.Discovery,
      {EMCP.Transport.STDIO, server: SonosMcp.MCP.Server}
    ]

    opts = [strategy: :one_for_one, name: SonosMcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
