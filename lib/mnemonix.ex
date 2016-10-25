defmodule Mnemonix do
  @moduledoc """
  Entry point to core Mnemonix operations.
  """
  
  alias Mnemonix.Store
  
  @type store :: any
  @type key   :: Store.key
  @type value :: Store.value
  
  @doc """
  Deletes the entries in `store` for a specific `key`.

  If the `key` does not exist, the contents of `store` will be unaffected.
  
  ## Examples
      iex> Mnemonix.Store.delete(%{a: 1, b: 2}, :a)
      %{b: 2}
      iex> Mnemonix.Store.delete(%{b: 2}, :a)
      %{b: 2}
  """
  @spec delete(store, key) :: store
  def delete(store, key) do
    with :ok <- GenServer.cast(store, {:delete, key}), do: store
  end
  
  @doc """
  Drops the given `keys` from `store`.
  
  ## Examples
      iex> Menmonix.Store.drop(%{a: 1, b: 2, c: 3}, [:b, :d])
      %{a: 1, c: 3}
  """
  @spec drop(store, Enumerable.t) :: store
  def drop(store, keys) do
    keys
   |> Enum.to_list
   |> drop_list(store)
 end

 defp drop_list([], store), do: store
 defp drop_list([key | rest], store) do
   drop_list(rest, delete(store, key))
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
  @spec fetch(store, key) :: {:ok, value} | :error
  def fetch(store, key) do
    GenServer.call(store, {:fetch, key})
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
  @spec fetch!(store, key) :: value | no_return
  def fetch!(store, key) do
    case fetch(store, key) do
      {:ok, value} -> value
      :error -> raise KeyError, key: key, term: store
    end
  end
  
  @doc """
  Gets the value for a specific `key`.
  
  If `key` does not exist, return the default value
  (`nil` if no default value).
  
  ## Examples
      iex> Mnemonix.Store.get(%{}, :a)
      nil
      iex> Mnemonix.Store.get(%{a: 1}, :a)
      1
      iex> Mnemonix.Store.get(%{a: 1}, :b)
      nil
      iex> Mnemonix.Store.get(%{a: 1}, :b, 3)
      3
  """
  @spec get(store, key) :: value
  @spec get(store, key, value) :: value
  def get(store, key, default \\ nil) do
    case fetch(store, key) do
      {:ok, value} -> value
      :error -> default
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
  @spec get_and_update(store, key, (value -> {get, value} | :pop)) :: {get, store} when get: term
  def get_and_update(store, key, fun) do
    current =
      case fetch(store, key) do
        {:ok, value} -> value
        :error -> nil
      end

    case fun.(current) do
      {get, update} -> {get, put(store, key, update)}
      :pop          -> {current, delete(store, key)}
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
    case fetch(store, key) do
      {:ok, value} ->
        case fun.(value) do
          {get, update} -> {get, put(store, key, update)}
          :pop          -> {value, pop(store, key)}
        end
      :error ->
        :erlang.error({:badkey, key})
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
  @spec get_lazy(store, key, (() -> value)) :: value
  def get_lazy(store, key, fun) when is_function(fun, 0) do
    case fetch(store, key) do
      {:ok, value} -> value
      :error -> fun.()
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
    GenServer.call(store, {:has_key?, key})
  end
  
  @doc """
  Returns all keys from `store`.
  
  ## Examples
      iex> Mnemonix.Store.keys(%{a: 1, b: 2})
      [:a, :b]
  """
  @spec keys(store) :: [key] | []
  def keys(store)do
    GenServer.call(store, {:keys})
  end
  
  @doc """
  Returns and removes the value associated with `key` in `store`.
  
  If no value is associated with the `key` but `default` is given,
  that will be returned instead without touching the store.
  
  ## Examples
      iex> Mnemonix.Store.pop(%{a: 1}, :a)
      {1, %{}}
      iex> Mnemonix.Store.pop(%{a: 1}, :b)
      {nil, %{a: 1}}
      iex> Mnemonix.Store.pop(%{a: 1}, :b, 3)
      {3, %{a: 1}}
  """
  @spec pop(store, key, value) :: {value, store}
  def pop(store, key, default \\ nil) do
    if has_key? store, key do
      {get(store, key), store}
    else
      {default, store}
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
    case fetch(store, key) do
      {:ok, value} -> {value, delete(store, key)}
      :error -> {fun.(), store}
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
  @spec put(store, key, value) :: store
  def put(store, key, value) do
    with :ok <- GenServer.cast(store, {:put, key, value}), do: store
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
    case has_key?(store, key) do
      true  -> store
      false -> put(store, key, value)
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
  @spec put_new_lazy(store, key, (() -> value)) :: store
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    case has_key?(store, key) do
      true  -> store
      false -> put(store, key, fun.())
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
  @spec update(store, key, value, (value -> value)) :: store
  def update(store, key, initial, fun) do
    case fetch(store, key) do
      {:ok, value} ->
        put(store, key, fun.(value))
      :error ->
        put(store, key, initial)
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
    case fetch(store, key) do
      {:ok, value} ->
        put(store, key, fun.(value))
      :error ->
        :erlang.error({:badkey, key})
    end
  end
  
end
