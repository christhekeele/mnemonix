defmodule Mnemonix.Adapters.Map do
  use Mnemonix.Adapter
  
  alias Mnemonix.Store
  
  @spec init(Store.opts) :: {Store.opts, Store.state}
  def init(opts) do
    {opts, %{}}
  end
  
  @spec keys(Store.t) :: {[Store.key] | [], Store.t}
  def keys(store = %Store{state: state}) do
    {Map.keys(state), store}
  end
  
  @spec has_key?(Store.t, Store.key) :: {boolean, Store.t}
  def has_key?(store = %Store{state: state}, key) do
    {Map.has_key?(state, key), store}
  end
  
  @spec fetch(Store.t, Store.key) :: { {:ok, Store.value} | nil, Store.t}
  def fetch(store = %Store{state: state}, key) do
    {Map.fetch(state, key), store}
  end
  
  @spec delete(Store.t, Store.key) :: Store.t
  def delete(store = %Store{state: state}, key) do
    %{store | state: Map.delete(state, key) }
  end
  
  @spec put(Store.t, Store.key, Store.value) :: Store.t
  def put(store = %Store{state: state}, key, value) do
    %{store | state: Map.put(state, key, value) }
  end
  
end