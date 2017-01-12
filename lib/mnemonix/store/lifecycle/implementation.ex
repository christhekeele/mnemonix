defmodule Mnemonix.Store.Lifecycle.Implementation do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false
      def teardown(reason, _store) do
        {:ok, reason}
      end
      defoverridable teardown: 2

    end
  end

end
