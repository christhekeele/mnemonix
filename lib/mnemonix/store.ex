defmodule Mnemonix.Store do
  @moduledoc """
  Container for store state that defers core store operations to an adapter.
  """
  
  defmacro __using__([]) do
    raise ArgumentError, "a `Mnemonix.Store` must supply an `:adapter`"
  end
  
  defmacro __using__(adapter: adapter) do
    
    quote location: :keep do
      def start_link(opts \\ []) do
        Mnemonix.start_link unquote(adapter), Keyword.put(opts, :name, __MODULE__)
      end
      use Mnemonix.Interface
    end
  end
  
  defstruct adapter: nil, config: [], state: nil
  @enforce_keys [:adapter]
  
  @type adapter :: Atom.t
  @type config  :: Keyword.t
  @type state   :: any
  
  @type key   :: any
  @type value :: any
  
  @type t :: %__MODULE__{adapter: adapter, config: config, state: state}
  
  @doc """
  Prepares a `store` by doing any setup, normalizing its `config`, and setting initial `state`.
  """
  @spec init(t) :: t
  def init(adapter, config \\ []) do
    {config, state} = adapter.init(config)
    %__MODULE__{adapter: adapter, config: config, state: state}
  end
  
  @doc """
  Returns all keys found in store and an updated `store`.
  """
  @spec keys(t) :: {[key] | [], t}
  def keys(store = %__MODULE__{adapter: adapter}) do
    adapter.keys(store)
  end
  
  @doc """
  Returns whether or not store contains `key` and an updated `store`.
  """
  @spec has_key?(t, key) :: {boolean, t}
  def has_key?(store = %__MODULE__{adapter: adapter}, key) do
    adapter.has_key?(store, key)
  end
  
  @doc """
  Returns value in store of `key` and an updated `store`.
  """
  @spec fetch(t, key) :: { {:ok, value} | nil, t}
  def fetch(store = %__MODULE__{adapter: adapter}, key) do
    adapter.fetch(store, key)
  end
  
  @doc """
  Puts `value` in `key` of store and returns an updated `store`.
  """
  @spec put(t, key, value) :: t
  def put(store = %__MODULE__{adapter: adapter}, key, value) do
    adapter.put(store, key, value)
  end
  
  
  @doc """
  Removes value at `key` of store and returns an updated `store`.
  """
  @spec delete(t, key) :: t
  def delete(store = %__MODULE__{adapter: adapter}, key) do
    adapter.delete(store, key)
  end
end