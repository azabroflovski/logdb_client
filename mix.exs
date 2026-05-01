defmodule LogdbClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :logdb_client,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {LogDB.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:websockex, "~> 0.5.1"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5.0"}
    ]
  end
end
