defmodule LogDB.Client.Connection do
  use GenServer
  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    conn_name = :"#{name}_conn"
    GenServer.start_link(__MODULE__, opts, name: conn_name)
  end

  def init(opts) do
    send(self(), :connect)

    {:ok,
     %{
       transport: Keyword.get(opts, :transport, LogDB.Client.Transport.HTTP),
       parser: Keyword.get(opts, :parser, LogDB.Client.Parser.Raw),
       opts: opts,
       transport_state: nil,
       connected: false,
       reconnect_attempts: 0,
       reconnect_delay: 5000,
       worker_name: Keyword.fetch!(opts, :name)
     }}
  end

  def handle_info(:connect, state) do
    case state.transport.connect(state.opts) do
      {:ok, t_state} ->
        Logger.info("[LogDB] Connected via #{inspect(state.transport)}")
        {:noreply, %{state | transport_state: t_state, connected: true, reconnect_attempts: 0}}

      {:error, reason} ->
        Logger.warning("[LogDB] Connection failed: #{inspect(reason)}. Retrying...")
        schedule_reconnect(state.reconnect_delay)

        {:noreply,
         %{
           state
           | connected: false,
             transport_state: nil,
             reconnect_attempts: state.reconnect_attempts + 1
         }}
    end
  end

  def handle_info({:logdb_event, type, raw_payload, meta}, state) do
    GenServer.cast(state.worker_name, {:process_event, type, raw_payload, meta})
    {:noreply, state}
  end

  def handle_info(:disconnect, state) do
    if state.transport_state, do: state.transport.disconnect(state.transport_state)
    schedule_reconnect(0)
    {:noreply, %{state | connected: false, transport_state: nil}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    require Logger
    Logger.warning("[LogDB] Remote transport process died: #{inspect(reason)}")

    schedule_reconnect(1000)
    {:noreply, %{state | connected: false, transport_state: nil}}
  end

  # NOTE: Performance issue (fucking genserver mailbox)
  # Iq 500 idea: run ack/nack/publish in caller side
  #
  def handle_call(:get_transport, _from, %{connected: true} = state) do
    {:reply, {:ok, state.transport, state.transport_state}, state}
  end

  def handle_call(:get_transport, _from, state) do
    {:reply, {:error, :disconnected}, state}
  end

  # NOTE: Performance issue (fucking genserver mailbox)
  # Why commented: see how works :get_transport
  #
  # def handle_call({:publish, type, payload, meta}, _from, state) do
  #   if state.connected do
  #     raw_payload = state.parser.encode(payload)
  #     res = state.transport.publish(state.transport_state, type, raw_payload, meta)
  #     {:reply, res, state}
  #   else
  #     {:reply, {:error, :disconnected}, state}
  #   end
  # end
  #
  # def handle_call({action, type, payload, meta}, _from, state) when action in [:ack, :nack] do
  #   if state.connected do
  #     res = apply(state.transport, action, [state.transport_state, type, payload, meta])
  #     {:reply, res, state}
  #   else
  #     {:reply, {:error, :disconnected}, state}
  #   end
  # end

  defp schedule_reconnect(delay) do
    Process.send_after(self(), :connect, delay)
  end
end
