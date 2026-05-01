defmodule LogDB.Client.Transport.Hybrid do
  @behaviour LogDB.Client.Transport

  def connect(opts) do
    case LogDB.Client.Transport.WebSocket.connect(opts) do
      {:ok, ws_pid} ->
        http_state = LogDB.Client.Transport.HTTP.build_state(opts)

        {:ok, %{ws_pid: ws_pid, http_state: http_state}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def disconnect(state) do
    LogDB.Client.Transport.WebSocket.disconnect(state.ws_pid)
  end

  def publish(state, type, payload, meta) do
    LogDB.Client.Transport.HTTP.publish(state.http_state, type, payload, meta)
  end

  def ack(state, ids) do
    LogDB.Client.Transport.HTTP.ack(state.http_state, ids)
  end

  def nack(state, ids) do
    LogDB.Client.Transport.HTTP.nack(state.http_state, ids)
  end

  def ping(state) do
    LogDB.Client.Transport.HTTP.ping(state.http_state)
  end

  def server_info(_state), do: %{transport: :hybrid_ws_http}
end
