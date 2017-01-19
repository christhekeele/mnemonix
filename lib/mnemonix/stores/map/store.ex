defmodule Mnemonix.Stores.Map do
  @moduledoc """
  A `Mnemonix.Store` that uses a map to store state.

  Intended to be an example for implementing the `Mnemonix.Store.Behaviour` and
  experimenting with the `Mnemonix` API rather than production usage.

  It intentionally doesn't override any optional callback with native versions
  so that the default implementations can be easily tested.

      iex> {:ok, store} = Mnemonix.Stores.Map.start_link
      iex> Mnemonix.put(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.delete(store, :foo)
      iex> Mnemonix.get(store, :foo)
      nil
  """

  use Mnemonix.Store.Behaviour
  use Mnemonix.Store.Types, [:store, :opts, :state, :key, :value]

  alias Mnemonix.Store

  @doc """
  Constructs a map to store data.

  ## Options

  - `initial:` An existing map to start the store with.

    *Default:* `%{}`
  """
  @spec setup(opts) :: {:ok, state}
  def setup(opts) do
    {:ok, Keyword.get(opts, :initial, %{})}
  end

  @spec delete(store, key) :: {:ok, store}
  def delete(store = %Store{state: map}, key) do
    {:ok, %{store | state: Map.delete(map, key)}}
  end

  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
  def fetch(store = %Store{state: map}, key) do
    {:ok, store, Map.fetch(map, key)}
  end

  @spec put(store, key, Store.value) :: {:ok, store}
  def put(store = %Store{state: map}, key, value) do
    {:ok, %{store | state: Map.put(map, key, value)}}
  end

end
