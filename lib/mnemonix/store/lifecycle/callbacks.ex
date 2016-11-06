defmodule Mnemonix.Store.Lifecycle.Callbacks do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false

      @spec terminate(reason, t) :: reason
        when reason: :normal | :shutdown | {:shutdown, term} | term

      def terminate(reason, store = %__MODULE__{impl: impl}) do
        with {:ok, reason} <- impl.teardown(reason, store) do
          reason
        end
      end

    end
  end

end
