defmodule LogDB.Client.Transport.WebSocket do
  @behaviour LogDB.Client.Transport

  alias LogDB.Client.ConnectionConfig
  require Logger

  use WebSockex

  @ping_interval 5_000

  def build_connection_link(opts) do
    connection = ConnectionConfig.from(opts)

    query_params = %{
      consumer_id: Keyword.get(opts, :consumer_id),
      stream: Keyword.get(opts, :stream)
    }

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

    {:ok, state}
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

  def handle_frame({:text, msg}, state) do
    %{"type" => type, "payload" => payload, "meta" => meta} = Jason.decode!(msg)

    send(state.parent, {:logdb_event, type, payload, meta})

    {:ok, state}
  end

  def handle_frame({:ping, _}, state) do
    {:reply, :pong, state}
  end
end
