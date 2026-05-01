defmodule LogDB.Client.Supervisor do
  use Supervisor

  def start_link({consumer_mod, opts}) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, {consumer_mod, opts}, name: :"#{name}_sup")
  end

  def init({consumer_mod, opts}) do
    children = [
      {LogDB.Client.Connection, opts},
      {LogDB.Client.Worker, Keyword.merge(opts, consumer_mod: consumer_mod)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
