defmodule LogDB.Client.Transport.HTTP do
  @behaviour LogDB.Client.Transport

  alias LogDB.Client.ConnectionConfig

  def build_state(opts) do
    connection = ConnectionConfig.from(opts)

    scheme = if connection.secure, do: "https", else: "http"

    uri_struct =
      %URI{
        scheme: scheme,
        host: connection.host,
        port: connection.port
      }

    %{url: URI.to_string(uri_struct), token: opts[:token]}
  end

  def connect(opts) do
    state = build_state(opts)

    parent_pid = self()

    {:ok, poller_pid} =
      Task.start_link(fn ->
        poll_loop(state, parent_pid)
      end)

    {:ok, Map.put(state, :poller_pid, poller_pid)}
  end

  def disconnect(state) do
    Process.exit(state.poller_pid, :kill)
    :ok
  end

  def publish(state, type, payload, meta) do
    body = %{
      events: [
        %{
          type: type,
          payload: payload,
          meta: meta
        }
      ]
    }

    case Req.post("#{state.url}/events", json: body, auth: {:bearer, state.token}) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def publish_batch(state, events) do
    body = %{
      events: events
    }

    case Req.post("#{state.url}/events", json: body, auth: {:bearer, state.token}) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def ack(state, ids) do
    body = %{
      ids: ids
    }

    case Req.post("#{state.url}/events/ack", json: body, auth: {:bearer, state.token}) do
      {:ok, response} -> response
      {:error, reason} -> {:error, reason}
    end
  end

  def nack(state, ids) do
    body = %{
      ids: ids
    }

    case Req.post("#{state.url}/events/nack", json: body, auth: {:bearer, state.token}) do
      {:ok, response} -> response
      {:error, reason} -> {:error, reason}
    end
  end

  def ping(state) do
    case Req.get("#{state.url}/ping", auth: {:bearer, state.token}) do
      {:ok, response} -> response.body
      _ -> {:error, :timeout}
    end
  end

  def server_info(_state), do: %{transport: :http_polling}

  defp poll_loop(state, parent_pid) do
    request_opts = [receive_timeout: 35_000, auth: {:bearer, state.token}]

    case Req.get("#{state.url}/events/poll", request_opts) do
      {:ok, %{status: 200, body: %{"events" => events}}} ->
        Enum.each(events, fn event ->
          raw_payload = Base.decode64!(event["payload"])
          send(parent_pid, {:logdb_event, event["type"], raw_payload, event["meta"]})
        end)

      {:ok, %{status: 204}} ->
        :ok

      error ->
        require Logger
        Logger.debug("[LogDB] Poller HTTP error: #{inspect(error)}")

        Process.sleep(1000)
    end

    poll_loop(state, parent_pid)
  end
end
