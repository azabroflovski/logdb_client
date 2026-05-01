defmodule LogDB.Client.ConnectionConfig do
  @enforce_keys [:host]
  defstruct host: nil,
            port: 80,
            secure: false,
            options: %{}

  @type t :: %__MODULE__{
          host: String.t(),
          port: integer(),
          secure: boolean(),
          options: map()
        }

  @is_true ["true", "1", "yes", "enable", "enabled"]
  @is_false ["false", "0", "no", "disable", "disabled"]

  def from(connection_string) when is_binary(connection_string) do
    parse_uri(connection_string)
  end

  def from([{_, _} | _] = opts) do
    if conn_str = Keyword.get(opts, :connection) do
      parse_uri(conn_str)
    else
      build_from_keywords(opts)
    end
  end

  def to_connection_string(%__MODULE__{} = config) do
    scheme = if config.secure, do: "logdbs", else: "logdb"

    query_string =
      if map_size(config.options) > 0 do
        "?" <> URI.encode_query(prepare_query_options(config.options))
      else
        ""
      end

    "#{scheme}://#{config.host}:#{config.port}#{query_string}"
  end

  defp parse_uri(uri_str) do
    uri = URI.parse(uri_str)

    secure =
      case uri.scheme do
        "logdbs" ->
          true

        "logdb" ->
          false

        _ ->
          raise ArgumentError,
                "Unsupported scheme: #{inspect(uri.scheme)}. Expected logdb or logdbs."
      end

    port = uri.port || if(secure, do: 443, else: 80)

    options =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.new(fn {k, v} -> {k, cast_boolean(v)} end)

    %__MODULE__{
      host: uri.host,
      port: port,
      secure: secure,
      options: options
    }
  end

  defp build_from_keywords(opts) do
    host = Keyword.fetch!(opts, :host)
    secure = Keyword.get(opts, :secure, false) |> cast_boolean()

    port = Keyword.get(opts, :port) || if(secure, do: 443, else: 80)

    options =
      opts
      |> Keyword.drop([:host, :port, :secure])
      |> Map.new(fn {k, v} -> {to_string(k), cast_boolean(v)} end)

    %__MODULE__{
      host: host,
      port: port,
      secure: secure,
      options: options
    }
  end

  defp cast_boolean(val) when is_binary(val) do
    val_lower = String.downcase(val)

    cond do
      val_lower in @is_true -> true
      val_lower in @is_false -> false
      true -> val
    end
  end

  defp cast_boolean(val), do: val

  defp prepare_query_options(options) do
    Map.new(options, fn
      {k, true} -> {k, "true"}
      {k, false} -> {k, "false"}
      {k, v} -> {k, to_string(v)}
    end)
  end
end
