defmodule MyApp.MyConsumer do
  use LogDB.Client.Consumer

  def init(_opts) do
    {:ok, %{processed: 0}}
  end

  def handle_connect(state) do
    IO.inspect("CONSUMER LEVEL HANDLE CONNECT")
    {:ok, state}
  end

  def handle_event(type, payload, meta, state) do
    IO.inspect("handle_event")
    IO.inspect(type)
    IO.inspect(payload)
    IO.inspect(meta)
    IO.inspect("-----------")
    # {:ack, state}
  end

  def handle_error(type, error) do
  end
end
