defmodule Mnemonix.Map.State do
  defstruct data: %{}, expiry: %{}
end

defmodule Mnemonix.Map.Store do
  @moduledoc """
  A Mnemonix.Store that uses a single map to store state.
  
  ## Options
  
  - `initial:` A map to start the store with.
    *Default*: %{}
  """
  
  use Mnemonix.Store
  alias Mnemonix.Store
  
  @typep store  :: Store.t
  @typep opts   :: Store.opts
  @typep state  :: Store.state
  @typep key    :: Store.key
  @typep value  :: Store.value
  # @typep ttl    :: Store.ttl # TODO: expiry
  
  @spec init(opts) :: {:ok, state}
  def init(opts) do
    {:ok, Keyword.get(opts, :initial, %{})}
  end
  
  @spec delete(store, key) :: {:ok, store}
  def delete(store = %Store{state: state}, key) do
    {:ok, %{store | state: Map.delete(state, key) }}
  end
  
  # TODO: expiry
  # @spec expires(store, key, ttl) :: {:ok, store}
  # def expires(store = %Store{state: state}, key, ttl) do
  #   {:ok, store}
  # end
  
  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
  def fetch(store = %Store{state: state}, key) do
    {:ok, store, Map.fetch(state, key)}
  end
  
  @spec put(store, key, Store.value) :: {:ok, store}
  def put(store = %Store{state: state}, key, value) do
    {:ok, %{store | state: Map.put(state, key, value) }}
  end
  
end