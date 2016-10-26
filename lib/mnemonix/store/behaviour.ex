defmodule Mnemonix.Store.Behaviour do
  @moduledoc false
  
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Behaviour.Default
    end
  end
  
  @type exception :: Exception.t
  @type msg       :: String.t
  
  @callback init(Store.opts) ::
    {:ok, Store.state} |
    {:ok, Store.state, timeout | :hibernate} |
    :ignore |
    {:stop, reason :: any}

####
# CORE
##
    
  @callback delete(Store.t, Store.key) ::
    {:ok, Store.t} |
    {:raise, exception, msg}
    
  @callback fetch(Store.t, Store.key) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @callback keys(Store.t) ::
    {:ok, Store.t, Store.keys} |
    {:raise, exception, msg}
    
  @callback put(Store.t, Store.key, Store.value) ::
    {:ok, Store.t} |
    {:raise, exception, msg}

####    
# OPTIONAL
##

  @optional_callbacks drop: 2
  @callback drop(Store.t, Store.keys) ::
    {:ok, Store.t} |
    {:raise, exception, msg}
  
  @optional_callbacks fetch!: 2
  @callback fetch!(Store.t, Store.key) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks get: 2
  @callback get(Store.t, Store.key) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks get: 3
  @callback get(Store.t, Store.key, Store.value) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks get_and_update: 3
  @callback get_and_update(Store.t, Store.key, fun) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks get_and_update!: 3
  @callback get_and_update!(Store.t, Store.key, fun) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks get_lazy: 3
  @callback get_lazy(Store.t, Store.key, fun) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
        
  @optional_callbacks has_key?: 2
  @callback has_key?(Store.t, Store.key) ::
    {:ok, Store.t, boolean} |
    {:raise, exception, msg}
  
  @optional_callbacks pop: 2
  @callback pop(Store.t, Store.key) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks pop: 3
  @callback pop(Store.t, Store.key, Store.value) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
  
  @optional_callbacks pop_lazy: 3
  @callback pop_lazy(Store.t, Store.key, fun) ::
    {:ok, Store.t, Store.value} |
    {:raise, exception, msg}
    
  @optional_callbacks put_new: 3
  @callback put_new(Store.t, Store.key, Store.value) ::
    {:ok, Store.t} |
    {:raise, exception, msg}
    
  @optional_callbacks put_new_lazy: 3
  @callback put_new_lazy(Store.t, Store.key, fun) ::
    {:ok, Store.t} |
    {:raise, exception, msg}
    
  @optional_callbacks update: 4
  @callback update(Store.t, Store.key, Store.value, fun) ::
    {:ok, Store.t} |
    {:raise, exception, msg}
  
  @optional_callbacks update!: 3
  @callback update!(Store.t, Store.key, fun) ::
    {:ok, Store.t} |
    {:raise, exception, msg}
end