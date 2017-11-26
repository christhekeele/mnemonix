defmodule Mnemonix.Stores.Map do
  @moduledoc """
  A `Mnemonix.Store` that uses a map to store state.

  Intended to be an example for implementing the `Mnemonix.Store.Behaviour` and
  experimenting with the `Mnemonix` API rather than production usage.

  It intentionally doesn't override any optional callback with native versions
  so that the default implementations can be easily tested.

      iex> {:ok, store} = Mnemonix.Stores.Map.start_link
      iex> Mnemonix.put(store, "foo", "bar")
      iex> Mnemonix.get(store, "foo")
      "bar"
      iex> Mnemonix.delete(store, "foo")
      iex> Mnemonix.get(store, "foo")
      nil

  This store supports the functions in `Mnemonix.Features.Enumerable`.
  """

  alias Mnemonix.Store

  use Store.Behaviour
  use Store.Translator.Raw

####
# Mnemonix.Store.Behaviours.Core
##

  @doc """
  Constructs a map to store data using provided `opts`.

  ## Options

  - `initial:` An existing map to start the store with.

    - *Default:* `%{}`
  """
  @impl Store.Behaviours.Core
  @spec setup(Store.options)
    :: {:ok, state :: term} | {:stop, reason :: any}
  def setup(_opts) do
    {:ok, %{}}
  end

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  @impl Store.Behaviours.Map
  @spec delete(Store.t, Mnemonix.key)
    :: {:ok, Store.t} | Store.Behaviour.exception
  def delete(store = %Store{state: map}, key) do
    {:ok, %{store | state: Map.delete(map, key)}}
  end

  @impl Store.Behaviours.Map
  @spec fetch(Store.t, Mnemonix.key)
    :: {:ok, Store.t, {:ok, Mnemonix.value} | :error} | Store.Behaviour.exception
  def fetch(store = %Store{state: map}, key) do
    {:ok, store, Map.fetch(map, key)}
  end

  @impl Store.Behaviours.Map
  @spec put(Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Store.t} | Store.Behaviour.exception
  def put(store = %Store{state: map}, key, value) do
    {:ok, %{store | state: Map.put(map, key, value)}}
  end

####
# Mnemonix.Store.Behaviours.Enumerable
##

  @doc """
  Returns `true`: this store supports the functions in `Mnemonix.Features.Enumerable`.
  """
  @impl Mnemonix.Store.Behaviours.Enumerable
  @spec enumerable?(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception
  def enumerable?(store) do
    {:ok, store, true}
  end

  @impl Mnemonix.Store.Behaviours.Enumerable
  @spec to_enumerable(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t} | Mnemonix.Store.Behaviour.exception
  def to_enumerable(store = %Store{state: map}) do
    {:ok, store, map}
  end

end
