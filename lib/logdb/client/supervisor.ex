defmodule LogDB.Client.Supervisor do
  use Supervisor

  # old version
  def start_link({consumer_mod, opts}) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, {consumer_mod, opts}, name: :"#{name}_sup")
  end

  def start_link(opts) when is_list(opts) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, {nil, opts}, name: :"#{name}_sup")
  end

  def init({consumer_mod, opts}) do
    children = [
      {LogDB.Client.Connection, opts}
    ]

    children =
      if consumer_mod do
        children ++ [{LogDB.Client.Worker, Keyword.merge(opts, consumer_mod: consumer_mod)}]
      else
        children
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
