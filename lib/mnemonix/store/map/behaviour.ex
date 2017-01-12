defmodule Mnemonix.Store.Map.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Map.Implementation
    end
  end

  use Mnemonix.Store.Types, [:store, :key, :value, :exception]

  @optional_callbacks fetch!: 2
  @callback fetch!(store, key) :: {:ok, store, value} | exception

  @optional_callbacks get: 2
  @callback get(store, key) :: {:ok, store, value} | exception

  @optional_callbacks get: 3
  @callback get(store, key, value) :: {:ok, store, value} | exception

  @optional_callbacks get_and_update: 3
  @callback get_and_update(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks get_and_update!: 3
  @callback get_and_update!(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks get_lazy: 3
  @callback get_lazy(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks has_key?: 2
  @callback has_key?(store, key) :: {:ok, store, boolean} | exception

  @optional_callbacks pop: 2
  @callback pop(store, key) :: {:ok, store, value} | exception

  @optional_callbacks pop: 3
  @callback pop(store, key, value) :: {:ok, store, value} | exception

  @optional_callbacks pop_lazy: 3
  @callback pop_lazy(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks put_new: 3
  @callback put_new(store, key, value) :: {:ok, store} | exception

  @optional_callbacks put_new_lazy: 3
  @callback put_new_lazy(store, key, fun) :: {:ok, store} | exception

  @optional_callbacks update: 4
  @callback update(store, key, value, fun) :: {:ok, store} | exception

  @optional_callbacks update!: 3
  @callback update!(store, key, fun) :: {:ok, store} | exception

end
