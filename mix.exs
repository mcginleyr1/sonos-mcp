defmodule Sonosex.MixProject do
  use Mix.Project

  def project do
    [
      app: :sonosex,
      version: "0.2.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [sonosex: [applications: [sonosex: :permanent]]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :xmerl],
      mod: {Sonosex, []}
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
