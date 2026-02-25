defmodule SonosMcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :sonos_mcp,
      version: "0.2.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [sonos_mcp: [applications: [sonos_mcp: :permanent]]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :xmerl],
      mod: {SonosMcp, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:emcp, "~> 0.3.2"}
    ]
  end
end
