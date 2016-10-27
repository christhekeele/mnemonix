defmodule Mnemonix do
  @moduledoc """
  This module provides easy access to `Mnemonix.Store` servers with a
  Map-like interface.
  
  In addition to Map-like behaviour, it supports:
  
  - `expires(store, key, ttl) :: store`
    
  Behaves exactly like Map, but without analogs for:
  
  - equal?(Map.t, Map.t) :: boolean
  - from_struct(Struct.t) :: Map.t
  - merge(Map.t, Map.t) :: Map.t
  - merge(Map.t, Map.t, callback) :: Map.t
  - new(Enum.t) :: Map.t
  - new(Enum.t, transform) :: Map.t
  - split(Map.t, keys) :: Map.t
  - take(Map.t, keys) :: Map.t
  - to_list(Map.t) :: Map.t
  
  """
  
  alias Mnemonix.Store
  
  @typep store  :: GenServer.server
  @typep key    :: Store.key
  @typep value  :: Store.value
  @typep keys   :: Store.keys
  @typep values :: Store.values
  @typep ttl    :: Store.ttl
  
####  
# CORE
##

  @doc """
  Deletes the entries in `store` for a specific `key`.

  If the `key` does not exist, the contents of `store` will be unaffected.

  ## Examples
      iex> Mnemonix.delete(%{a: 1, b: 2}, :a)
      %{b: 2}
      iex> Mnemonix.delete(%{b: 2}, :a)
      %{b: 2}
  """
  @spec delete(store, key) :: store | no_return
  def delete(store, key) do
    case GenServer.call(store, {:delete, key}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Sets the entry under `key` to expire in `ttl` seconds.

  If the `key` does not exist, the contents of `store` will be unaffected.

  ## Examples
      iex> Mnemonix.expires(%{a: 1, b: 2}, :a, 100)
      %{a: 1, b: 2}
      iex> :timer.sleep(100)
      iex> Mnemonix.get(%{a: 1, b: 2}, :a)
      nil
  """
  @spec expires(store, key, ttl) :: store | no_return
  def expires(store, key, ttl) do
    case GenServer.call(store, {:expire, key, ttl}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
   
  @doc """
  Fetches the value for a specific `key` and returns it in a tuple.
 
  If the `key` does not exist, returns `:error`.
 
  ## Examples
      iex> Mnemonix.fetch(%{a: 1}, :a)
      {:ok, 1}
      iex> Mnemonix.fetch(%{a: 1}, :b)
      :error
  """
  @spec fetch(store, key) :: {:ok, value} | :error | no_return
  def fetch(store, key) do
    case GenServer.call(store, {:fetch, key}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Returns all keys from `store`.
  
  ## Examples
      iex> Mnemonix.keys(%{a: 1, b: 2})
      [:a, :b]
  """
  @spec keys(store) :: [key] | [] | no_return
  def keys(store) do
    case GenServer.call(store, {:keys}) do
      {:ok, keys} -> keys
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Puts the given `value` under `key`.
  
  ## Examples
      iex> Mnemonix.put(%{a: 1}, :b, 2)
      %{a: 1, b: 2}
      iex> Mnemonix.put(%{a: 1, b: 2}, :a, 3)
      %{a: 3, b: 2}
  """
  @spec put(store, key, value) :: store | no_return
  def put(store, key, value) do
    case GenServer.call(store, {:put, key, value}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end

####  
# MAP FUNCTIONS
##

  @doc """
  Drops the given `keys` from `store`.
  
  ## Examples
      iex> Menmonix.Store.drop(%{a: 1, b: 2, c: 3}, [:b, :d])
      %{a: 1, c: 3}
  """
  @spec drop(store, Enumerable.t) :: store | no_return
  def drop(store, keys) do
    case GenServer.call(store, {:drop, keys}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
 
 # TODO:
  # equal?(map1, map2)
  #   Checks if two maps are equal
 
  @doc """
  Fetches the value for specific `key`.
 
  If `key` does not exist, a `KeyError` is raised.
 
  ## Examples
      iex> Mnemonix.fetch!(%{a: 1}, :a)
      1
      iex> Mnemonix.fetch!(%{a: 1}, :b)
      ** (KeyError) key :b not found in: %{a: 1}
  """
  @spec fetch!(store, key) :: {:ok, value} | :error | no_return
  def fetch!(store, key) do
    case GenServer.call(store, {:fetch!, key}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
 
  # TODO:
  # from_struct(struct)
  #  Converts a struct to map
  
  @doc """
  Gets the value for a specific `key`.
  
  If `key` does not exist, returns `nil`.
  
  ## Examples
      iex> Mnemonix.get(%{}, :a)
      nil
      iex> Mnemonix.get(%{a: 1}, :a)
      1
      iex> Mnemonix.get(%{a: 1}, :b)
      nil
  """
  @spec get(store, key) :: value | no_return
  def get(store, key) do
    case GenServer.call(store, {:get, key}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Gets the value for a specific `key` with `default`.
   
  If `key` does not exist, returns `default`.
   
  ## Examples
      iex> Mnemonix.get(%{}, :a)
      nil
      iex> Mnemonix.get(%{a: 1}, :a)
      1
      iex> Mnemonix.get(%{a: 1}, :b, 3)
      3
  """
  @spec get(store, key, value) :: value | no_return
  def get(store, key, default) do
    case GenServer.call(store, {:get, key, default}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Gets the value from `key` and updates it, all in one pass.
  
  This `fun` argument receives the value of `key` (or `nil` if `key`
  is not present) and must return a two-element tuple: the "get" value
  (the retrieved value, which can be operated on before being returned)
  and the new value to be stored under `key`. The `fun` may also
  return `:pop`, implying the current value shall be removed
  from `store` and returned.
  
  The returned value is a tuple with the "get" value returned by
  `fun` and a new map with the updated value under `key`.
  
  ## Examples
      iex> Mnemonix.get_and_update(%{a: 1}, :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {1, %{a: "new value!"}}
      iex> Mnemonix.get_and_update(%{a: 1}, :b, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {nil, %{b: "new value!", a: 1}}
      iex> Mnemonix.get_and_update(%{a: 1}, :a, fn _ -> :pop end)
      {1, %{}}
      iex> Mnemonix.get_and_update(%{a: 1}, :b, fn _ -> :pop end)
      {nil, %{a: 1}}
  """
  @spec get_and_update(store, key, (value -> {get, value} | :pop)) :: {get, store} | no_return when get: term
  def get_and_update(store, key, fun) do
    case GenServer.call(store, {:get_and_update, key, fun}) do
      {:ok, value} -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Gets the value from `key` and updates it. Raises if there is no `key`.
  
  This `fun` argument receives the value of `key` and must return a
  two-element tuple: the "get" value (the retrieved value, which can be
  operated on before being returned) and the new value to be stored under
  `key`.
  
  The returned value is a tuple with the "get" value returned by `fun` and a
  a reference to the `store` with the updated value under `key`.
  
  ## Examples
      iex> Mnemonix.get_and_update!(%{a: 1}, :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {1, %{a: "new value!"}}
      iex> Mnemonix.get_and_update!(%{a: 1}, :b, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      ** (KeyError) key :b not found
      iex> Mnemonix.get_and_update!(%{a: 1}, :a, fn _ ->
      ...>   :pop
      ...> end)
      {1, %{}}
  """
  @spec get_and_update!(store, key, (value -> {get, value})) :: {get, store} | no_return when get: term
  def get_and_update!(store, key, fun) do
    case GenServer.call(store, {:get_and_update!, key, fun}) do
      {:ok, value} -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Gets the value for a specific `key`.
  
  If `key` does not exist, lazily evaluates `fun` and returns its result.
  
  This is useful if the default value is very expensive to calculate or
  generally difficult to setup and teardown again.
  
  ## Examples
      iex> map = %{a: 1}
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   13
      ...> end
      iex> Mnemonix.get_lazy(map, :a, fun)
      1
      iex> Mnemonix.get_lazy(map, :b, fun)
      13
  """
  @spec get_lazy(store, key, (() -> value)) :: value | no_return
  def get_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:get_lazy, key, fun}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Returns whether a given `key` exists in the given `store`.
  
  ## Examples
      iex> Mnemonix.has_key?(%{a: 1}, :a)
      true
      iex> Mnemonix.has_key?(%{a: 1}, :b)
      false
  """
  @spec has_key?(store, key) :: boolean
  def has_key?(store, key) do
    case GenServer.call(store, {:has_key?, key}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  # TODO:
  # merge(map1, map2)
  #   Merges two maps into one
  
  # TODO:
  # merge(map1, map2, callback)
  #   Merges two maps into one
  
  @doc """
  Starts a new Mnemonix.Map.Store server with an empty map.
  """
  @spec new() :: store
  def new() do
    with {:ok, store} <- Mnemonix.Store.start_link(Mnemonix.Map.Store), do: store
  end
  
  # TODO:
  # new(enumerable)
  #   Creates a map from an enumerable
  
  # TODO:
  # new(enumerable, transform)
  #   Creates a map from an enumerable via the transformation function
    
  @doc """
  Returns and removes the value associated with `key` in `store`.
  
  If no value is associated with the `key`, `nil` is returned
  
  ## Examples
      iex> Mnemonix.pop(%{a: 1}, :a)
      {1, %{}}
      iex> Mnemonix.pop(%{a: 1}, :b)
      {nil, %{a: 1}}
  """
  @spec pop(store, key) :: {value, store}
  def pop(store, key) do
    case GenServer.call(store, {:pop, key}) do
      {:ok, value} -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end
  
  
  @doc """
  Returns and removes the value associated with `key` in `store` with `default`.
  
  If no value is associated with the `key` but `default` is given,
  that will be returned instead without touching the store.
  
  ## Examples
      iex> Mnemonix.pop(%{a: 1}, :a)
      {1, %{}}
      iex> Mnemonix.pop(%{a: 1}, :b, 3)
      {3, %{a: 1}}
  """
  @spec pop(store, key, any) :: {value, store}
  def pop(store, key, default) do
    case GenServer.call(store, {:pop, key, default}) do
      {:ok, value} -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Lazily returns and removes the value associated with `key` in `store`.
  
  This is useful if the default value is very expensive to calculate or
  generally difficult to setup and teardown again.
  
  ## Examples
      iex> map = %{a: 1}
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   13
      ...> end
      iex> Mnemonix.pop_lazy(map, :a, fun)
      {1, %{}}
      iex> Mnemonix.pop_lazy(map, :b, fun)
      {13, %{a: 1}}
  """
  @spec pop_lazy(store, key, (() -> value)) :: {value, store}
  def pop_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:pop_lazy, key, fun}) do
      {:ok, value} -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Puts the given `value` under `key` unless the entry `key`
  already exists.
  
  ## Examples
      iex> Mnemonix.put_new(%{a: 1}, :b, 2)
      %{b: 2, a: 1}
      iex> Mnemonix.put_new(%{a: 1, b: 2}, :a, 3)
      %{a: 1, b: 2}
  """
  @spec put_new(store, key, value) :: store
  def put_new(store, key, value) do
    case GenServer.call(store, {:put_new, key, value}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Evaluates `fun` and puts the result under `key`
  in `store` unless `key` is already present.
  
  This is useful if the value is very expensive to calculate or
  generally difficult to setup and teardown again.
  
  ## Examples
      iex> store = %{a: 1}
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   3
      ...> end
      iex> Mnemonix.put_new_lazy(store, :a, fun)
      %{a: 1}
      iex> Mnemonix.put_new_lazy(store, :b, fun)
      %{a: 1, b: 3}
  """
  @spec put_new_lazy(store, key, (() -> value)) :: store | no_return
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:put_new_lazy, key, fun}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  # TODO:
  # split(store, keys)
  #   Takes all entries corresponding to the given keys and extracts them into a map
    
  # TODO:
  # take(store, keys)
  #   Takes all entries corresponding to the given keys and returns them in a map
    
  # TODO:
  # to_list(store)
  #   Returns a Keyword list of the contents of `store`.
  
  @doc """
  Updates the `key` in `store` with the given function.
  If the `key` does not exist, inserts the given `initial` value.
  ## Examples
      iex> Mnemonix.update(%{a: 1}, :a, 13, &(&1 * 2))
      %{a: 2}
      iex> Mnemonix.update(%{a: 1}, :b, 11, &(&1 * 2))
      %{a: 1, b: 11}
  """
  @spec update(store, key, value, (value -> value)) :: store | no_return
  def update(store, key, initial, fun) do
    case GenServer.call(store, {:update, key, initial, fun}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Updates the `key` with the given function.
  
  If the `key` does not exist, raises `KeyError`.
  
  ## Examples
      iex> Mnemonix.update!(%{a: 1}, :a, &(&1 * 2))
      %{a: 2}
      iex> Mnemonix.update!(%{a: 1}, :b, &(&1 * 2))
      ** (KeyError) key :b not found
  """
  @spec update!(store, key, (value -> value)) :: store | no_return
  def update!(store, key, fun) do
    case GenServer.call(store, {:update!, key, fun}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  
  
  @doc """
  Returns all values from `store`.
  
  ## Examples
      iex> Mnemonix.values(%{a: 1, b: 2})
      [1, 2]
  """
  @spec values(store) :: values | no_return
  def values(store) do
    case GenServer.call(store, {:values}) do
      {:ok, values} -> values
      {:raise, type, args} -> raise type, args
    end
  end
  
end
