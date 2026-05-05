defmodule LogdbClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :logdb_client,
      version: "0.2.5",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      # mod: {LogDB.Application, []},
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

  defp description() do
    "Client for Logdb event bus"
  end

  defp package() do
    [
      name: "logdb_client",
      licenses: ["MIT"],
      links: %{"GitLab" => "https://gitlab.com/tender.pro/as/logdb_client"}
    ]
  end
end
