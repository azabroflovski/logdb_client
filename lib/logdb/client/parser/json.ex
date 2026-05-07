defmodule LogDB.Client.Parser.Json do
  @behaviour LogDB.Client.Parser

  def encode(payload), do: payload

  def decode(payload) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, result} ->
        result

      {:error, error} ->
        error
    end
  end

  def decode(payload), do: payload
end
