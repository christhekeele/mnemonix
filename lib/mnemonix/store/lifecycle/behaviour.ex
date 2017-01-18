defmodule Mnemonix.Store.Lifecycle.Behaviour do
  @moduledoc false

  use Mnemonix.Store.Types, [:store]

  @optional_callbacks teardown: 2
  @callback teardown(reason, store) :: {:ok, reason} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__

      @doc false
      def teardown(reason, _store) do
        {:ok, reason}
      end
      defoverridable teardown: 2
    end
  end

end
