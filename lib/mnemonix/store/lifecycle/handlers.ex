defmodule Mnemonix.Store.Lifecycle.Handlers do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false

      @spec terminate(reason, store) :: reason
        when reason: :normal | :shutdown | {:shutdown, term} | term

      def terminate(reason, store = %Mnemonix.Store{impl: impl}) do
        with {:ok, reason} <- impl.teardown(reason, store) do
          reason
        end
      end

    end
  end

end
