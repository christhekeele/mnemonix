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

  alias Mnemonix.Store

  @doc """
  Constructs a map to store data.

  ## Options

  - `initial:` An existing map to start the store with.

    *Default:* `%{}`
  """
  @spec setup(Mnemonix.Store.options)
    :: {:ok, state :: term} | {:stop, reason :: any}
  def setup(opts) do
    {:ok, Keyword.get(opts, :initial, %{})}
  end

  @spec delete(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def delete(store = %Store{state: map}, key) do
    {:ok, %{store | state: Map.delete(map, key)}}
  end

  @spec fetch(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, {:ok, Mnemonix.value} | :error} | Mnemonix.Store.Behaviour.exception
  def fetch(store = %Store{state: map}, key) do
    {:ok, store, Map.fetch(map, key)}
  end

  @spec put(Mnemonix.Store.t, Mnemonix.key, Store.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def put(store = %Store{state: map}, key, value) do
    {:ok, %{store | state: Map.put(map, key, value)}}
  end

end
