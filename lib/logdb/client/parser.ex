defmodule LogDB.Client.Parser do
  @callback encode(term()) :: binary()
  @callback decode(binary()) :: term()
end
