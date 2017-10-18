defmodule Mnemonix.Features.Map do
  @moduledoc """
  Functions to operate on key/value pairs within a store.

  All of these functions are available on the main `Mnemonix` module.
  """

  defmacro __using__(opts) do
    quote do
      use Mnemonix.Feature, [unquote_splicing(opts), module: unquote(__MODULE__)]
    end
  end

  @doc """
  Removes the entry under `key` in `store`.

  If the `key` does not exist, the contents of `store` will be unaffected.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.get(store, :a)
      1
      iex> Mnemonix.delete(store, :a)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @spec delete(Mnemonix.store, Mnemonix.key)
    :: Mnemonix.store | no_return
  def delete(store, key) do
    case GenServer.call(store, {:delete, key}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Retrievs the value of the entry under `key` in `store`.

  If the `key` does not exist, returns `:error`, otherwise returns `{:ok, value}`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.fetch(store, :a)
      {:ok, 1}
      iex> Mnemonix.fetch(store, :b)
      :error
  """
  @spec fetch(Mnemonix.store, Mnemonix.key)
    :: {:ok, Mnemonix.value} | :error | no_return
  def fetch(store, key) do
    case GenServer.call(store, {:fetch, key}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Creates a new entry for `value` under `key` in `store`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.get(store, :b)
      nil
      iex> Mnemonix.put(store, :b, 2)
      iex> Mnemonix.get(store, :b)
      2
  """
  @spec put(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.store | no_return
  def put(store, key, value) do
    case GenServer.call(store, {:put, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Drops the given `keys` from the `store`.

  If `keys` contains keys that are not in the store, they’re simply ignored.

  ## Examples

      iex> store = Mnemonix.drop Mnemonix.new(%{a: 1, b: 2, d: 4}), [:a, :b, :c]
      iex> Mnemonix.get store, :a
      nil
      iex> Mnemonix.get store, :d
      4

  """
  @spec drop(Mnemonix.store, Enumerable.t)
    :: %{Mnemonix.key => Mnemonix.value} | no_return
  def drop(store, keys) do
    case GenServer.call(store, {:drop, keys}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Fetches the value for specific `key`.

  If `key` does not exist, a `KeyError` is raised.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.fetch!(store, :a)
      1
      iex> Mnemonix.fetch!(store, :b)
      ** (KeyError) key :b not found in: Mnemonix.Stores.Map
  """
  @spec fetch!(Mnemonix.store, Mnemonix.key)
    :: {:ok, Mnemonix.value} | :error | no_return
  def fetch!(store, key) do
    case GenServer.call(store, {:fetch!, key}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Gets the value for a specific `key`.

  If `key` does not exist, returns `nil`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.get(store, :a)
      1
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec get(Mnemonix.store, Mnemonix.key)
    :: Mnemonix.value | no_return
  def get(store, key) do
    case GenServer.call(store, {:get, key}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Gets the value for a specific `key` with `default`.

  If `key` does not exist, returns `default`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.get(store, :a, 2)
      1
      iex> Mnemonix.get(store, :b, 2)
      2
  """
  @spec get(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.value | no_return
  def get(store, key, default) do
    case GenServer.call(store, {:get, key, default}) do
      {:ok, value}         -> value
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
  `fun` and a reference to the `store` with the updated value under `key`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update(store, :a, fn current ->
      ...>   {current, "new value!"}
      ...> end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      "new value!"

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update(store, :b, fn current ->
      ...>   {current, "new value!"}
      ...> end)
      iex> value
      nil
      iex> Mnemonix.get(store, :b)
      "new value!"

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update(store, :a, fn _ -> :pop end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      nil

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update(store, :b, fn _ -> :pop end)
      iex> value
      nil
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec get_and_update(Mnemonix.store, Mnemonix.key, (Mnemonix.value -> {get, Mnemonix.value} | :pop))
    :: {get, Mnemonix.store} | no_return when get: term
  def get_and_update(store, key, fun) do
    case GenServer.call(store, {:get_and_update, key, fun}) do
      {:ok, value}         -> {value, store}
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

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update!(store, :a, fn current ->
      ...>   {current, "new value!"}
      ...> end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      "new value!"

      iex> store = Mnemonix.new(%{a: 1})
      iex> {_value, ^store} = Mnemonix.get_and_update!(store, :b, fn current ->
      ...>   {current, "new value!"}
      ...> end)
      ** (KeyError) key :b not found in: Mnemonix.Stores.Map

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update!(store, :a, fn _ -> :pop end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      nil

      iex> store = Mnemonix.new(%{a: 1})
      iex> {_value, ^store} = Mnemonix.get_and_update!(store, :b, fn _ -> :pop end)
      ** (KeyError) key :b not found in: Mnemonix.Stores.Map
  """
  @spec get_and_update!(Mnemonix.store, Mnemonix.key, (Mnemonix.value -> {get, Mnemonix.value}))
    :: {get, Mnemonix.store} | no_return when get: term
  def get_and_update!(store, key, fun) do
    case GenServer.call(store, {:get_and_update!, key, fun}) do
      {:ok, value}         -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Gets the value for a specific `key`.

  If `key` does not exist, lazily evaluates `fun` and returns its result.

  This is useful if the default value is very expensive to calculate or
  generally difficult to setup and teardown again.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   13
      ...> end
      iex> Mnemonix.get_lazy(store, :a, fun)
      1
      iex> Mnemonix.get_lazy(store, :b, fun)
      13
  """
  @spec get_lazy(Mnemonix.store, Mnemonix.key, (() -> Mnemonix.value))
    :: Mnemonix.value | no_return
  def get_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:get_lazy, key, fun}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Returns whether a given `key` exists in the given `store`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.has_key?(store, :a)
      true
      iex> Mnemonix.has_key?(store, :b)
      false
  """
  @spec has_key?(Mnemonix.store, Mnemonix.key) :: boolean
  def has_key?(store, key) do
    case GenServer.call(store, {:has_key?, key}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Returns and removes the value associated with `key` in `store`.

  If no value is associated with the `key`, `nil` is returned.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.pop(store, :a)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      nil
      iex> {value, ^store} = Mnemonix.pop(store, :b)
      iex> value
      nil
  """
  @spec pop(Mnemonix.store, Mnemonix.key)
    :: {Mnemonix.value, Mnemonix.store}
  def pop(store, key) do
    case GenServer.call(store, {:pop, key}) do
      {:ok, value}         -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end


  @doc """
  Returns and removes the value associated with `key` in `store` with `default`.

  If no value is associated with the `key` but `default` is given,
  that will be returned instead without touching the store.

  ## Examples

      iex> store = Mnemonix.new()
      iex> {value, ^store} = Mnemonix.pop(store, :a)
      iex> value
      nil
      iex> {value, ^store} = Mnemonix.pop(store, :b, 2)
      iex> value
      2
  """
  @spec pop(Mnemonix.store, Mnemonix.key, default :: term)
    :: {Mnemonix.value, Mnemonix.store}
  def pop(store, key, default) do
    case GenServer.call(store, {:pop, key, default}) do
      {:ok, value}         -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Lazily returns and removes the value associated with `key` in `store`.

  This is useful if the default value is very expensive to calculate or
  generally difficult to setup and teardown again.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   13
      ...> end
      iex> {value, ^store} = Mnemonix.pop_lazy(store, :a, fun)
      iex> value
      1
      iex> {value, ^store} = Mnemonix.pop_lazy(store, :b, fun)
      iex> value
      13
  """
  @spec pop_lazy(Mnemonix.store, Mnemonix.key, (() -> Mnemonix.value))
    :: {Mnemonix.value, Mnemonix.store}
  def pop_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:pop_lazy, key, fun}) do
      {:ok, value}         -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Puts the given `value` under `key` unless the entry `key` already exists.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.put_new(store, :b, 2)
      iex> Mnemonix.get(store, :b)
      2
      iex> Mnemonix.put_new(store, :b, 3)
      iex> Mnemonix.get(store, :b)
      2
  """
  @spec put_new(Mnemonix.store, Mnemonix.key, Mnemonix.value) :: Mnemonix.store
  def put_new(store, key, value) do
    case GenServer.call(store, {:put_new, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Evaluates `fun` and puts the result under `key` in `store` unless `key` is already present.

  This is useful if the value is very expensive to calculate or generally difficult to setup and teardown again.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   13
      ...> end
      iex> Mnemonix.put_new_lazy(store, :b, fun)
      iex> Mnemonix.get(store, :b)
      13
      iex> Mnemonix.put_new_lazy(store, :a, fun)
      iex> Mnemonix.get(store, :a)
      1
  """
  @spec put_new_lazy(Mnemonix.store, Mnemonix.key, (() -> Mnemonix.value))
    :: Mnemonix.store | no_return
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:put_new_lazy, key, fun}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Alters the value stored under `key` to `value` if it already exists in `store`.

  If the `key` does not exist, the contents of `store` will be unaffected.

  ## Examples
     iex> store = Mnemonix.new(%{a: 1})
     iex> Mnemonix.replace(store, :a, 3)
     iex> Mnemonix.get(store, :a)
     3
     iex> Mnemonix.replace(store, :b, 2)
     iex> Mnemonix.get(store, :b)
     nil

  """
  @spec replace(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.store | no_return
  def replace(store, key, value) do
    case GenServer.call(store, {:replace, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Alters the value stored under `key` to `value` if it already exists in `store`.

  If the `key` does not exist, raises `KeyError`.

  ## Examples
     iex> store = Mnemonix.new(%{a: 1})
     iex> Mnemonix.replace!(store, :a, 3)
     iex> Mnemonix.get(store, :a)
     3
     iex> Mnemonix.replace!(store, :b, 2)
     ** (KeyError) key :b not found in: Mnemonix.Stores.Map

  """
  @spec replace!(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.store | no_return
  def replace!(store, key, value) do
    case GenServer.call(store, {:replace!, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Takes all entries corresponding to the given `keys` and removes them from the `store` into a separate map.

  Returns a tuple with the new map and the store updated with removed keys.

  If `keys` contains keys that are not in the store, they’re simply ignored.

  ## Examples

      iex> {removed, store} = Mnemonix.split Mnemonix.new(%{a: 1, b: 2, d: 4}), [:a, :b, :c]
      iex> removed
      %{a: 1, b: 2}
      iex> Mnemonix.get(store, :a)
      nil
      iex> Mnemonix.get(store, :c)
      nil
      iex> Mnemonix.get(store, :d)
      4

      iex> {removed, _store} = Mnemonix.split Mnemonix.new, [:a, :b, :c]
      iex> removed
      %{}

  """
  @spec split(Mnemonix.store, Enumerable.t)
    :: {%{Mnemonix.key => Mnemonix.value}, Mnemonix.store} | no_return
  def split(store, keys) do
    case GenServer.call(store, {:split, keys}) do
      {:ok, result}        -> {result, store}
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Returns a map of all key/value pairs in `store` where the key is in `keys`.

  If `keys` contains keys that are not in the store, they’re simply ignored.

  ## Examples

      iex> Mnemonix.take Mnemonix.new(%{a: 1, b: 2, d: 4}), [:a, :b, :c]
      %{a: 1, b: 2}

      iex> Mnemonix.take Mnemonix.new, [:a, :b, :c]
      %{}

  """
  @spec take(Mnemonix.store, Enumerable.t)
    :: %{Mnemonix.key => Mnemonix.value} | no_return
  def take(store, keys) do
    case GenServer.call(store, {:take, keys}) do
      {:ok, result}        -> result
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Updates the value at `key` in `store` with the given `function`.

  If the `key` does not exist, inserts the given `initial` value.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.update(store, :a, 13, &(&1 * 2))
      iex> Mnemonix.get(store, :a)
      2
      iex> Mnemonix.update(store, :b, 13, &(&1 * 2))
      iex> Mnemonix.get(store, :b)
      13
  """
  @spec update(Mnemonix.store, Mnemonix.key, Mnemonix.value, (Mnemonix.value -> Mnemonix.value))
    :: Mnemonix.store
  def update(store, key, initial, function) do
    case GenServer.call(store, {:update, key, initial, function}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Updates the value at `key` in `store` with the given `function`.

  If the `key` does not exist, raises `KeyError`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.update!(store, :a, &(&1 * 2))
      iex> Mnemonix.get(store, :a)
      2
      iex> Mnemonix.update!(store, :b, &(&1 * 2))
      ** (KeyError) key :b not found in: Mnemonix.Stores.Map
  """
  @spec update!(Mnemonix.store, Mnemonix.key, (Mnemonix.value -> Mnemonix.value))
    :: Mnemonix.store | no_return
  def update!(store, key, function) do
    case GenServer.call(store, {:update!, key, function}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

end
