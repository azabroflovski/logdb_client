defmodule LogDB.Client.Consumer do
  @callback init(opts :: keyword()) :: {:ok, term()} | {:error, term()}

  @callback handle_connect(state :: term()) :: {:ok, term()}
  @callback handle_ready(state :: term()) :: {:ok, term()}
  @callback handle_disconnect(reason :: term(), state :: term()) :: {:ok, term()}
  @callback handle_event(type :: String.t(), payload :: term(), meta :: map(), state :: term()) ::
              {:ack, term()} | {:defer, term()}

  @callback handle_error(error :: term(), event :: term()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour LogDB.Client.Consumer
      require Logger

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {LogDB.Client.Supervisor, :start_link, [{__MODULE__, opts}]},
          type: :supervisor
        }
      end

      def init(_opts), do: {:ok, %{}}
      def handle_connect(state), do: {:ok, state}
      def handle_ready(state), do: {:ok, state}
      def handle_disconnect(_reason, state), do: {:ok, state}

      def handle_error(error, event) do
        type = event["type"]
        Logger.error("[LogDB] consumer error [#{type}]: #{inspect(error)}")
      end

      defoverridable init: 1,
                     handle_connect: 1,
                     handle_ready: 1,
                     handle_disconnect: 2,
                     handle_error: 2
    end
  end
end
