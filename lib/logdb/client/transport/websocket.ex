defmodule LogDB.Client.Transport.WebSocket do
  @behaviour LogDB.Client.Transport

  alias LogDB.Client.ConnectionConfig
  require Logger

  use WebSockex

  @ping_interval 5_000

  def build_connection_link(opts) do
    connection = ConnectionConfig.from(opts)

    query_params =
      %{
        consumer_id: Keyword.get(opts, :consumer_id),
        stream: Keyword.get(opts, :stream)
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    uri = %URI{
      scheme: if(connection.secure, do: "wss", else: "ws"),
      host: connection.host,
      port: connection.port,
      path: "/ws",
      query: URI.encode_query(query_params)
    }

    WebSockex.Conn.new(uri,
      extra_headers: [
        {"Authorization", "Bearer #{opts[:token]}"}
      ]
    )
  end

  def connect(opts) do
    state = %{
      parent: self()
    }

    connection = build_connection_link(opts)

    WebSockex.start_link(connection, __MODULE__, state)
  end

  def disconnect(pid) do
    Process.exit(pid, :normal)
    :ok
  end

  def handle_connect(_conn, state) do
    Logger.info("[LogDB] WebSocket Connected")

    send(state.parent, {:transport_status, :connected})
    send(state.parent, {:transport_status, :ready})

    schedule_ping()

    {:ok, state}
  end

  def handle_info(:send_ping, state) do
    schedule_ping()

    {:reply, {:text, "ping"}, state}
  end

  def handle_info(_message, state) do
    {:ok, state}
  end

  def subscribe(pid, stream, consumer_id) do
    msg = %{
      "cmd" => "subscribe",
      "params" => %{
        "stream" => stream,
        "consumer_id" => consumer_id
      }
    }

    WebSockex.send_frame(pid, {:text, Jason.encode!(msg)})
    :ok
  end

  # NOTE: implement
  #
  # def publish(_pid, _type, _payload, _meta) do
  # end

  # TODO: implement
  # def ack(pid, ids) do
  # end
  #
  # TODO: implement
  # def nack(pid, ids) do
  # end

  def ping(pid) do
    WebSockex.send_frame(pid, :ping)
  end

  # TODO: implement
  # def server_info(_pid) do
  # end

  def handle_disconnect(reason, state) do
    Logger.warning("[LogDB] Disconnected: #{inspect(reason)}")
    send(state.parent, {:transport_status, :disconnected})
    {:ok, state}
  end

  def handle_frame({:text, "pong"}, state) do
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    %{"type" => type, "payload" => payload, "meta" => meta} = Jason.decode!(msg)

    send(state.parent, {:logdb_event, type, payload, meta})

    {:ok, state}
  end

  defp schedule_ping do
    Process.send_after(self(), :send_ping, @ping_interval)
  end
end
