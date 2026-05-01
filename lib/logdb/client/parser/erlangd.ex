defmodule LogDB.Client.Parser.Erlangd do
  @behaviour LogDB.Client.Parser

  def encode(payload) do
    try do
      {:ok, :erlang.term_to_binary(payload, compression: 6)}
    rescue
      _ -> {:error, :encoding_failed}
    end
  end

  # 131 - detect for erlang term
  def decode(<<131, _rest::binary>> = payload) do
    case safe_decode(payload) do
      {:ok, term} -> {:ok, term}
      {:error, _reason} -> {:ok, payload}
    end
  end

  def decode(payload) when is_binary(payload) do
    {:ok, payload}
  end

  def decode(_), do: {:error, :not_a_binary}

  defp safe_decode(payload) do
    try do
      {:ok, :erlang.binary_to_term(payload, [:safe])}
    rescue
      ArgumentError -> {:error, :unsafe_or_invalid}
      _ -> {:error, :failed}
    end
  end
end
