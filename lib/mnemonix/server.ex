defmodule Mnemonix.Server do

  alias Mnemonix.Store
  
  def start_link(adapter, opts \\ []) do
    {config, opts} = Keyword.pop_first(opts, :config, [])
    GenServer.start_link(__MODULE__, {adapter, config}, opts)
  end
    
  use GenServer

  def init({adapter}), do: init({adapter, []})
  def init({adapter, config}) do
    {:ok, Store.init(adapter, config)}
  end

  def handle_call({:fetch, key}, _, store = %Store{}) do
    {value, store} = Store.fetch(store, key)
    {:reply, value, store}
  end

  def handle_call({:has_key?, key}, _, store = %Store{}) do
    {value, store} = Store.has_key?(store, key)
    {:reply, value, store}
  end

  def handle_call({:keys}, _, store = %Store{}) do
    {value, store} = Store.keys(store)
    {:reply, value, store}
  end

  def handle_cast({:put, key, value}, store = %Store{}) do
    {:noreply, Store.put(store, key, value)}
  end

  def handle_cast({:delete, key}, store = %Store{}) do
    {:noreply, Store.delete(store, key)}
  end
  
end