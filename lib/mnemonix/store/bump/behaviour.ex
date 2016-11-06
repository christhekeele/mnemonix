defmodule Mnemonix.Store.Bump.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Bump.Functions
    end
  end

  use Mnemonix.Store.Types, [:store, :key, :bump_op, :exception]

  @optional_callbacks bump: 3
  @callback bump(store, key, amount :: term) :: {:ok, store, bump_op} | exception

  @optional_callbacks bump!: 3
  @callback bump!(store, key, amount :: term) :: {:ok, store} | exception

  @optional_callbacks increment: 2
  @callback increment(store, key) :: {:ok, store} | exception

  @optional_callbacks increment: 3
  @callback increment(store, key, amount :: term) :: {:ok, store} | exception

  @optional_callbacks decrement: 2
  @callback decrement(store, key) :: {:ok, store} | exception

  @optional_callbacks decrement: 3
  @callback decrement(store, key, amount :: term) :: {:ok, store} | exception

end
