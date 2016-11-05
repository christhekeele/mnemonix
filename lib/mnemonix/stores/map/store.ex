defmodule Mnemonix.Map.Store do
  @moduledoc """
  A `Mnemonix.Store` that uses a map to store state.

  Intended to be an example for implementing the `Mnemonix.Store.Behaviour` and
  experimenting with the `Mnemonix` API rather than production usage.

  It intentionally doesn't override any optional callback with native versions
  so that the default implementations can be easily tested.

      iex> {:ok, store} = Mnemonix.Map.Store.start_link
      iex> Mnemonix.put(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.delete(store, :foo)
      iex> Mnemonix.get(store, :foo)
      nil
  """

  use Mnemonix.Store.Behaviour
  alias Mnemonix.Store

  @typep store  :: Store.t
  @typep opts   :: Store.opts
  @typep state  :: Store.state
  @typep key    :: Store.key
  @typep value  :: Store.value
  # @typep ttl    :: Store.ttl # TODO: expiry

  @doc """
  Constructs a map to store data.

  ## Options

  - `initial:` An existing map to start the store with.

    *Default:* `%{}`
  """
  @spec init(opts) :: {:ok, state}
  def init(opts) do
    {:ok, Keyword.get(opts, :initial, %{})}
  end

  @spec delete(store, key) :: {:ok, store}
  def delete(store = %Store{state: map}, key) do
    {:ok, %{store | state: Map.delete(map, key)}}
  end

  # TODO: expiry
  # @spec expires(store, key, ttl) :: {:ok, store}
  # def expires(store = %Store{state: state}, key, ttl) do
  #   {:ok, store}
  # end

  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
  def fetch(store = %Store{state: map}, key) do
    {:ok, store, Map.fetch(map, key)}
  end

  @spec put(store, key, Store.value) :: {:ok, store}
  def put(store = %Store{state: map}, key, value) do
    {:ok, %{store | state: Map.put(map, key, value)}}
  end

end
