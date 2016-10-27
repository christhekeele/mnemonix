defmodule Mnemonix.Store.Behaviour do
  @moduledoc false
  
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Behaviour.Default
      
      def start_link(opts) do
        Mnemonix.Store.start_link(__MODULE__, opts)
      end
      def start_link(init, opts) do
        Mnemonix.Store.start_link({__MODULE__, init}, opts)
      end
    end
  end
  
  @typep store :: Store.t
  @typep key   :: Store.key
  @typep value :: Store.value
  # @typep ttl   :: Store.ttl # TODO: expiry
  
  @typep exception :: Exception.t
  @typep msg       :: String.t
  
  @callback init(Store.opts) ::
    {:ok, Store.state} |
    {:ok, Store.state, timeout | :hibernate} |
    :ignore |
    {:stop, reason :: any}

####
# CORE
##
    
  @callback delete(store, key) ::
    {:ok, store} |
    {:raise, exception, msg}
    
  # TODO: expiry
  # @callback expires(store, key, ttl) ::
  #   {:ok, store} |
  #   {:raise, exception, msg}
    
  @callback fetch(store, key) ::
    {:ok, store, value} |
    {:raise, exception, msg}
    
  @callback put(store, key, value) ::
    {:ok, store} |
    {:raise, exception, msg}

####    
# MAP FUNCTIONS
##
  
  @optional_callbacks fetch!: 2
  @callback fetch!(store, key) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks get: 2
  @callback get(store, key) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks get: 3
  @callback get(store, key, value) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks get_and_update: 3
  @callback get_and_update(store, key, fun) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks get_and_update!: 3
  @callback get_and_update!(store, key, fun) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks get_lazy: 3
  @callback get_lazy(store, key, fun) ::
    {:ok, store, value} |
    {:raise, exception, msg}
        
  @optional_callbacks has_key?: 2
  @callback has_key?(store, key) ::
    {:ok, store, boolean} |
    {:raise, exception, msg}
  
  @optional_callbacks pop: 2
  @callback pop(store, key) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks pop: 3
  @callback pop(store, key, value) ::
    {:ok, store, value} |
    {:raise, exception, msg}
  
  @optional_callbacks pop_lazy: 3
  @callback pop_lazy(store, key, fun) ::
    {:ok, store, value} |
    {:raise, exception, msg}
    
  @optional_callbacks put_new: 3
  @callback put_new(store, key, value) ::
    {:ok, store} |
    {:raise, exception, msg}
    
  @optional_callbacks put_new_lazy: 3
  @callback put_new_lazy(store, key, fun) ::
    {:ok, store} |
    {:raise, exception, msg}
    
  @optional_callbacks update: 4
  @callback update(store, key, value, fun) ::
    {:ok, store} |
    {:raise, exception, msg}
  
  @optional_callbacks update!: 3
  @callback update!(store, key, fun) ::
    {:ok, store} |
    {:raise, exception, msg}
    
end