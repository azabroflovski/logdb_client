defmodule LogDB.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {MyApp.MyConsumer,
       [
         name: :logdb,
         connection: "logdb://127.0.0.1:4000?node_name=logdb",
         token: "aSQ3XgxxG6o0QsH2hgKjOV-50DYA0IeMPA99GvNgUfU",
         consumer_id: "NDJlOWMxOWYtNzVlNC00ZjIxLWFjNDQtMTYzZWJhMzIzMDIzOmdheV9jb25zdW1lcg",
         stream: "default",
         transport: LogDB.Client.Transport.Erlangd,
         parser: LogDB.Client.Parser.Erlangd
       ]},
      {LogDB.Client.Supervisor,
       [
         name: :logdb_2,
         connection: "logdb://127.0.0.1:4000?node_name=logdb",
         token: "aSQ3XgxxG6o0QsH2hgKjOV-50DYA0IeMPA99GvNgUfU",
         transport: LogDB.Client.Transport.Erlangd
       ]}
    ]

    opts = [strategy: :one_for_one, name: LogDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
