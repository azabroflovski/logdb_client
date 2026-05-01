defmodule LogDB.Client.Consumer do
  @callback init(opts :: keyword()) :: {:ok, term()} | {:error, term()}
  @callback handle_event(type :: String.t(), payload :: term(), meta :: map(), state :: term()) ::
              {:ack, term()} | {:defer, term()}
  @callback handle_error(type :: String.t(), error :: term()) :: any()

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

      def handle_error(type, error) do
        Logger.error("LogDB event error [#{type}]: #{inspect(error)}")
      end

      defoverridable init: 1, handle_error: 2
    end
  end
end
