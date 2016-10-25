defmodule Mnemonix.Adapter do
  @moduledoc """
  Callbacks that power Mnemonix adapters.
  """
  
  alias Mnemonix.Store
  
  @doc """
  Does any store setup, normalizes `opts`, and provides initial `state`.
  """
  @callback init(Store.opts) :: {Store.opts, Store.state}
  
  @doc """
  Returns all keys found in store and an updated `conn`.
  """
  @callback keys(Store.t) :: {[Store.key] | [], Store.t}
  
  @doc """
  Returns whether or not store contains `key` and an updated `conn`.
  """
  @callback has_key?(Store.t, Store.key) :: {boolean, Store.t}
  
  @doc """
  Returns value in store of `key` and an updated `conn`.
  """
  @callback fetch(Store.t, Store.key) :: { {:ok, Store.value} | nil, Store.t}
  
  @doc """
  Removes value at `key` of store and returns an updated `conn`.
  """
  @callback delete(Store.t, Store.key) :: Store.t
  
  @doc """
  Puts `value` in `key` of store and returns an updated `conn`.
  """
  @callback put(Store.t, Store.key, Store.value) :: Store.t
  
  
  @optional_callbacks has_key?: 2
  
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
      
      def has_key?(conn, key) do
        key in keys(conn)
      end
      
      defoverridable has_key?: 2
    end
  end
  
end