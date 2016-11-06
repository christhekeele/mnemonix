defmodule Mnemonix.Store.Lifecycle.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Lifecycle.Functions
    end
  end

  use Mnemonix.Store.Types, [:store]

  @optional_callbacks teardown: 2
  @callback teardown(reason, store) :: {:ok, reason} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

end
