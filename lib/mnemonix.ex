defmodule Mnemonix do
  @moduledoc """
  Interface to Memonix.Server methods.
  """
  
  alias Mnemonix.Store
  
  @type store :: GenServer.server
  @type key   :: Store.key
  @type value :: Store.value
  
####  
# CORE
##

  @doc """
  Deletes the entries in `store` for a specific `key`.

  If the `key` does not exist, the contents of `store` will be unaffected.

  ## Examples
      iex> Mnemonix.Store.delete(%{a: 1, b: 2}, :a)
      %{b: 2}
      iex> Mnemonix.Store.delete(%{b: 2}, :a)
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
  Fetches the value for a specific `key` and returns it in a tuple.
 
  If the `key` does not exist, returns `:error`.
 
  ## Examples
      iex> Mnemonix.Store.fetch(%{a: 1}, :a)
      {:ok, 1}
      iex> Mnemonix.Store.fetch(%{a: 1}, :b)
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
      iex> Mnemonix.Store.keys(%{a: 1, b: 2})
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
      iex> Mnemonix.Store.put(%{a: 1}, :b, 2)
      %{a: 1, b: 2}
      iex> Mnemonix.Store.put(%{a: 1, b: 2}, :a, 3)
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
# OPTIONAL
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
  
 @doc """
 Fetches the value for specific `key`.
 
 If `key` does not exist, a `KeyError` is raised.
 
 ## Examples
     iex> Mnemonix.Store.fetch!(%{a: 1}, :a)
     1
     iex> Mnemonix.Store.fetch!(%{a: 1}, :b)
     ** (KeyError) key :b not found in: %{a: 1}
 """
 @spec fetch!(store, key) :: {:ok, value} | :error | no_return
 def fetch!(store, key) do
   case GenServer.call(store, {:fetch!, key}) do
     {:ok, value} -> value
     {:raise, type, args} -> raise type, args
   end
 end
  
  @doc """
  Gets the value for a specific `key`.
  
  If `key` does not exist, returns `nil`.
  
  ## Examples
      iex> Mnemonix.Store.get(%{}, :a)
      nil
      iex> Mnemonix.Store.get(%{a: 1}, :a)
      1
      iex> Mnemonix.Store.get(%{a: 1}, :b)
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
      iex> Mnemonix.Store.get(%{}, :a)
      nil
      iex> Mnemonix.Store.get(%{a: 1}, :a)
      1
      iex> Mnemonix.Store.get(%{a: 1}, :b, 3)
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
      iex> Mnemonix.Store.get_and_update(%{a: 1}, :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {1, %{a: "new value!"}}
      iex> Mnemonix.Store.get_and_update(%{a: 1}, :b, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {nil, %{b: "new value!", a: 1}}
      iex> Mnemonix.Store.get_and_update(%{a: 1}, :a, fn _ -> :pop end)
      {1, %{}}
      iex> Mnemonix.Store.get_and_update(%{a: 1}, :b, fn _ -> :pop end)
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
      iex> Mnemonix.Store.get_and_update!(%{a: 1}, :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {1, %{a: "new value!"}}
      iex> Mnemonix.Store.get_and_update!(%{a: 1}, :b, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      ** (KeyError) key :b not found
      iex> Mnemonix.Store.get_and_update!(%{a: 1}, :a, fn _ ->
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
      iex> Mnemonix.Store.get_lazy(map, :a, fun)
      1
      iex> Mnemonix.Store.get_lazy(map, :b, fun)
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
      iex> Mnemonix.Store.has_key?(%{a: 1}, :a)
      true
      iex> Mnemonix.Store.has_key?(%{a: 1}, :b)
      false
  """
  @spec has_key?(store, key) :: boolean
  def has_key?(store, key) do
    case GenServer.call(store, {:has_key?, key}) do
      {:ok, value} -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Returns and removes the value associated with `key` in `store`.
  
  If no value is associated with the `key`, `nil` is returned
  
  ## Examples
      iex> Mnemonix.Store.pop(%{a: 1}, :a)
      {1, %{}}
      iex> Mnemonix.Store.pop(%{a: 1}, :b)
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
      iex> Mnemonix.Store.pop(%{a: 1}, :a)
      {1, %{}}
      iex> Mnemonix.Store.pop(%{a: 1}, :b, 3)
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
      iex> Mnemonix.Store.pop_lazy(map, :a, fun)
      {1, %{}}
      iex> Mnemonix.Store.pop_lazy(map, :b, fun)
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
      iex> Mnemonix.Store.put_new(%{a: 1}, :b, 2)
      %{b: 2, a: 1}
      iex> Mnemonix.Store.put_new(%{a: 1, b: 2}, :a, 3)
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
      iex> Mnemonix.Store.put_new_lazy(store, :a, fun)
      %{a: 1}
      iex> Mnemonix.Store.put_new_lazy(store, :b, fun)
      %{a: 1, b: 3}
  """
  @spec put_new_lazy(store, key, (() -> value)) :: store | no_return
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:put_new_lazy, key, fun}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Updates the `key` in `store` with the given function.
  If the `key` does not exist, inserts the given `initial` value.
  ## Examples
      iex> Mnemonix.Store.update(%{a: 1}, :a, 13, &(&1 * 2))
      %{a: 2}
      iex> Mnemonix.Store.update(%{a: 1}, :b, 11, &(&1 * 2))
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
      iex> Mnemonix.Store.update!(%{a: 1}, :a, &(&1 * 2))
      %{a: 2}
      iex> Mnemonix.Store.update!(%{a: 1}, :b, &(&1 * 2))
      ** (KeyError) key :b not found
  """
  @spec update!(store, key, (value -> value)) :: store | no_return
  def update!(store, key, fun) do
    case GenServer.call(store, {:update!, key, fun}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
end
