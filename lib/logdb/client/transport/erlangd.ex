defmodule LogDB.Client.Transport.Erlangd do
  @behaviour LogDB.Client.Transport

  alias LogDB.Client.ConnectionConfig

  require Logger

  def connect(opts) do
    connection = ConnectionConfig.from(opts)
    node_name = connection.options["node_name"]

    node = :"#{node_name}@#{connection.host}"
    token = Keyword.fetch!(opts, :token)

    Node.connect(node)

    consumer_opts = [
      consumer_id: Keyword.get(opts, :consumer_id),
      stream: Keyword.get(opts, :stream, "default"),
      owner: self()
    ]

    try do
      case :erpc.call(node, LogDB.API.Erlangd.Connection, :open, [token, consumer_opts]) do
        {:ok, remote_pid} ->
          monitor_ref = Process.monitor(remote_pid)

          {:ok, %{remote_pid: remote_pid, monitor_ref: monitor_ref, node: node}}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e in ErlangError ->
        {:error, :nodedown}
    end
  end

  def disconnect(state) do
    Process.demonitor(state.monitor_ref, [:flush])

    GenServer.cast(state.remote_pid, :close)
    :ok
  end

  def publish(state, type, payload, meta) do
    GenServer.call(state.remote_pid, {:publish, type, payload, meta})
  end

  def ack(state, ids) do
    GenServer.call(state.remote_pid, {:ack, ids})
  end

  def nack(state, ids) do
    GenServer.call(state.remote_pid, {:nack, ids})
  end

  def ping(state) do
    if Process.alive?(state.remote_pid) do
      :ok
    else
      {:error, :dead_process}
    end
  end

  def server_info(state), do: %{transport: :erlang_distribution, node: state.node}
end
