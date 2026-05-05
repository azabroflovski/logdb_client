defmodule LogDB.Client.Transport do
  @type state :: term()
  @type opts :: keyword()

  @callback connect(opts) :: {:ok, state} | {:error, term()}
  @callback disconnect(state) :: :ok
  @callback subscribe(state :: term(), stream :: String.t(), consumer_id :: String.t()) ::
              :ok | {:error, term()}
  @callback publish(state, type :: String.t(), payload :: binary(), meta :: map()) ::
              :ok | {:error, term()}
  @callback ack(state, type :: String.t(), payload :: binary(), meta :: map()) ::
              :ok | {:error, term()}
  @callback nack(state, type :: String.t(), payload :: binary(), meta :: map()) ::
              :ok | {:error, term()}
  @callback server_info(state) :: map()
  @callback ping(state) :: :ok | {:error, term()}
end
