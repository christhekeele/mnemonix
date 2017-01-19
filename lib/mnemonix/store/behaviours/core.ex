defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
    end
  end

  use Mnemonix.Store.Types, [:store, :opts, :state, :key, :value, :exception]

  @callback setup(opts) :: {:ok, state} | :ignore | {:stop, reason :: term}

  @callback delete(store, key) :: {:ok, store} | exception

  @callback fetch(store, key) :: {:ok, store, value} | exception

  @callback put(store, key, value) :: {:ok, store} | exception

end
