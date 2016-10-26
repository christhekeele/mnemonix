defmodule Mnemonix.Map.Store do
  use Mnemonix.Store
  alias Mnemonix.Store
  
  @spec init(Store.opts) :: {:ok, Store.state}
  def init(opts) do
    {:ok, Keyword.get(opts, :initial, %{})}
  end
  
  @spec put(Store.t, Store.key, Store.value) :: Store.t
  def put(store = %Store{state: state}, key, value) do
    {:ok, %{store | state: Map.put(state, key, value) }}
  end
  
  @spec fetch(Store.t, Store.key) :: { {:ok, Store.value} | nil, Store.t}
  def fetch(store = %Store{state: state}, key) do
    {:ok, store, Map.fetch(state, key)}
  end
  
  @spec delete(Store.t, Store.key) :: Store.t
  def delete(store = %Store{state: state}, key) do
    {:ok, %{store | state: Map.delete(state, key) }}
  end
  
  @spec keys(Store.t) :: {[Store.key] | [], Store.t}
  def keys(store = %Store{state: state}) do
    {:ok, store, Map.keys(state)}
  end
  
end