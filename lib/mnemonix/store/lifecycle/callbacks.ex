defmodule Mnemonix.Store.Lifecycle.Callbacks do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      ####
      # REQUIRED
      ##

      @doc false

      @spec init({adapter, opts}) ::
        {:ok, state} |
        {:ok, state, timeout | :hibernate} |
        :ignore |
        {:stop, reason} when reason: term, timeout: pos_integer

      def init({adapter, opts}) do
        case adapter.init(opts) do
          {:ok, state}          -> {:ok, new(adapter, opts, state)}
          {:ok, state, timeout} -> {:ok, new(adapter, opts, state), timeout}
          other                 -> other
        end
      end

      defp new(adapter, opts, state) do
        %__MODULE__{adapter: adapter, opts: opts, state: state}
      end

      ####
      # OPTIONAL
      ##

      @doc false

      @spec terminate(reason, t) :: reason
        when reason: :normal | :shutdown | {:shutdown, term} | term

      def terminate(reason, store = %__MODULE__{adapter: adapter}) do
        with {:ok, reason} <- adapter.teardown(reason, store) do
          reason
        end
      end

    end
  end

end
