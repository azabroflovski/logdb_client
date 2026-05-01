defmodule LogDB.Client.Worker do
  use GenServer
  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    consumer_mod = Keyword.fetch!(opts, :consumer_mod)
    parser = Keyword.get(opts, :parser, LogDB.Client.Parser.Raw)
    name = Keyword.fetch!(opts, :name)

    case consumer_mod.init(opts) do
      {:ok, user_state} ->
        {:ok,
         %{
           consumer_mod: consumer_mod,
           user_state: user_state,
           parser: parser,
           name: name
         }}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_cast({:process_event, type, raw_payload, meta}, state) do
    payload = state.parser.decode(raw_payload)

    try do
      case state.consumer_mod.handle_event(type, payload, meta, state.user_state) do
        {:ack, new_user_state} ->
          LogDB.ack(state.name, [meta["_ack_id"]])
          {:noreply, %{state | user_state: new_user_state}}

        {:nack, new_user_state} ->
          LogDB.nack(state.name, [meta["_ack_id"]])
          {:noreply, %{state | user_state: new_user_state}}

        {:defer, new_user_state} ->
          {:noreply, %{state | user_state: new_user_state}}
      end
    rescue
      e ->
        state.consumer_mod.handle_error(type, e)
        {:noreply, state}
    end
  end
end
