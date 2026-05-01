defmodule LogDB do
  def publish(name, type, payload, meta \\ %{}) do
    with_transport(name, fn mod, state ->
      mod.publish(state, type, payload, meta)
    end)
  end

  def ack(name, ids) do
    with_transport(name, fn mod, state ->
      mod.ack(state, ids)
    end)
  end

  def nack(name, ids) do
    with_transport(name, fn mod, state ->
      mod.nack(state, ids)
    end)
  end

  def ping(name) do
    with_transport(name, fn mod, state ->
      mod.ping(state)
    end)
  end

  def server_info(name) do
    with_transport(name, fn mod, state ->
      {:ok, mod.server_info(state)}
    end)
  end

  defp connection_name(name), do: :"#{name}_conn"

  defp with_transport(name, callback) do
    case GenServer.call(connection_name(name), :get_transport) do
      {:ok, mod, transport_state} ->
        callback.(mod, transport_state)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
