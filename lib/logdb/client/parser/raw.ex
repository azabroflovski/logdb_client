defmodule LogDB.Client.Parser.Raw do
  @behaviour LogDB.Client.Parser

  def encode(payload), do: payload
  def decode(payload), do: payload
end
