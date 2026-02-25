defmodule Sonosex do
  use Application

  def start(_type, _args) do
    EMCP.SessionStore.ETS.init()

    children = [
      Sonosex.Discovery,
      {EMCP.Transport.STDIO, server: Sonosex.MCP.Server}
    ]

    opts = [strategy: :one_for_one, name: Sonosex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
