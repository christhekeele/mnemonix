defmodule Mnemonix do
  @moduledoc """
  Easy access to `Mnemonix.Store` servers with a Map-like interface.
  
  Rather than a map, you can use the pid or `GenServer.server/0` name returned
  by `Mnemonix.Store.start_link/2` to perform operations on Mnemonix stores.
  
  The `new/0`, `new/1`, and `new/3` functions start links to a `Mnemonix.Map.Store`
  (mimicing to `Map.new`) to make it easy to play with the `Mnemonix` interface:
  
      iex> store = Mnemonix.new(fizz: 1) 
      iex> Mnemonix.get(store, :foo) 
      nil
      iex> Mnemonix.get(store, :fizz)
      1
      iex> Mnemonix.put_new(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.put_new(store, :foo, "baz")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.put(store, :foo, "baz")
      iex> Mnemonix.get(store, :foo)
      "baz"
      iex> Mnemonix.get(store, :fizz)
      1
      iex> Mnemonix.get_and_update(store, :fizz, &({&1, &1 * 2}))
      iex> Mnemonix.get_and_update(store, :fizz, &({&1, &1 * 2}))
      iex> Mnemonix.get(store, :fizz)
      4
    
  These functions behave exactly like their Map counteparts. However, `Mnemonix`
  doesn't supply analogs for functions that assume a store can be exhaustively
  iterated or fit into a specific shape:
  
  - equal?(Map.t, Map.t) :: boolean
  - from_struct(Struct.t) :: Map.t
  - keys(Map.t) :: [keys]
  - merge(Map.t, Map.t) :: Map.t
  - merge(Map.t, Map.t, callback) :: Map.t
  - split(Map.t, keys) :: Map.t
  - take(Map.t, keys) :: Map.t
  - to_list(Map.t) :: Map.t
  - values(Map.t) :: [values]
  """
  
  alias Mnemonix.Store
  
  @typep store  :: GenServer.server
  @typep key    :: Store.key
  @typep value  :: Store.value
  # @typep ttl    :: Store.ttl # TODO: expiry
  
####  
# CORE
##

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
  @spec delete(store, key) :: store | no_return
  def delete(store, key) do
    case GenServer.call(store, {:delete, key}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  # TODO: expiry
  # @doc """
  # Sets the entry under `key` to expire in `ttl` seconds.
  # 
  # If the `key` does not exist, the contents of `store` will be unaffected.
  # 
  # ## Examples
  
  #     iex> store = Mnemonix.new(%{a: 1})
  #     iex> Mnemonix.expires(store, :a, 100)
  #     iex> :timer.sleep(101)
  #     iex> Mnemonix.get(store, :a)
  #     nil
  # """
  # @spec expires(store, key, ttl) :: store | no_return
  # def expires(store, key, ttl) do
  #   case GenServer.call(store, {:expire, key, ttl}) do
  #     :ok                  -> store
  #     {:raise, type, args} -> raise type, args
  #   end
  # end
   
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
  @spec fetch(store, key) :: {:ok, value} | :error | no_return
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
  @spec put(store, key, value) :: store | no_return
  def put(store, key, value) do
    case GenServer.call(store, {:put, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

####  
# MAP FUNCTIONS
##
 
  @doc """
  Fetches the value for specific `key`.
 
  If `key` does not exist, a `KeyError` is raised.
 
  ## Examples
  
      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.fetch!(store, :a)
      1
      iex> Mnemonix.fetch!(store, :b)
      ** (KeyError) key :b not found in: Mnemonix.Map.Store
  """
  @spec fetch!(store, key) :: {:ok, value} | :error | no_return
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
  @spec get(store, key) :: value | no_return
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
  @spec get(store, key, value) :: value | no_return
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
      iex> {value, ^store} = Mnemonix.get_and_update(store, :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      "new value!"
      
      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update(store, :b, fn current_value ->
      ...>   {current_value, "new value!"}
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
  @spec get_and_update(store, key, (value -> {get, value} | :pop)) :: {get, store} | no_return when get: term
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
      iex> {value, ^store} = Mnemonix.get_and_update!(store, :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      "new value!"
      
      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update!(store, :b, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      ** (KeyError) key :b not found in: Mnemonix.Map.Store
      
      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update!(store, :a, fn _ -> :pop end)
      iex> value
      1
      iex> Mnemonix.get(store, :a)
      nil
      
      iex> store = Mnemonix.new(%{a: 1})
      iex> {value, ^store} = Mnemonix.get_and_update!(store, :b, fn _ -> :pop end)
      ** (KeyError) key :b not found in: Mnemonix.Map.Store
  """
  @spec get_and_update!(store, key, (value -> {get, value})) :: {get, store} | no_return when get: term
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
  @spec get_lazy(store, key, (() -> value)) :: value | no_return
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
  @spec has_key?(store, key) :: boolean
  def has_key?(store, key) do
    case GenServer.call(store, {:has_key?, key}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Starts a new `Mnemonix.Map.Store server` with an empty map.
  
  ## Examples
  
      iex> store = Mnemonix.new
      iex> Mnemonix.get(store, :a)
      nil
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec new() :: store
  def new() do
    with {:ok, store} <- Mnemonix.Store.start_link(Mnemonix.Map.Store), do: store
  end
  
  @doc """
  Starts a new `Mnemonix.Map.Store` server from the `enumerable`.
  
  Duplicated keys are removed; the latest one prevails.
  
  ## Examples
  
      iex> store = Mnemonix.new(a: 1)
      iex> Mnemonix.get(store, :a)
      1
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec new(Enum.t) :: store
  def new(enumerable) do
    init = {Mnemonix.Map.Store, [initial: Map.new(enumerable)]}
    with {:ok, store} <- Mnemonix.Store.start_link(init), do: store
  end
  
  @doc """
  Starts a new `Mnemonix.Map.Store` server from the `enumerable` via the `transformation` function.

  Duplicated keys are removed; the latest one prevails.
  
  ## Examples
  
      iex> store = Mnemonix.new(%{"A" => 0}, fn {key, value} ->
      ...>  { String.downcase(key), value + 1 }
      ...> end )
      iex> Mnemonix.get(store, "a")
      1
      iex> Mnemonix.get(store, "A")
      nil
  """
  @spec new(Enum.t, (term -> {key, value})) :: store
  def new(enumerable, transform) do
    init = {Mnemonix.Map.Store, [initial: Map.new(enumerable, transform)]}
    with {:ok, store} <- Mnemonix.Store.start_link(init), do: store
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
  @spec pop(store, key) :: {value, store}
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
  @spec pop(store, key, term) :: {value, store}
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
  @spec pop_lazy(store, key, (() -> value)) :: {value, store}
  def pop_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:pop_lazy, key, fun}) do
      {:ok, value}         -> {value, store}
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Puts the given `value` under `key` unless the entry `key`
  already exists.
  
  ## Examples
  
      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.put_new(store, :b, 2)
      iex> Mnemonix.get(store, :b)
      2
      iex> Mnemonix.put_new(store, :b, 3)
      iex> Mnemonix.get(store, :b)
      2
  """
  @spec put_new(store, key, value) :: store
  def put_new(store, key, value) do
    case GenServer.call(store, {:put_new, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Evaluates `fun` and puts the result under `key`
  in `store` unless `key` is already present.
  
  This is useful if the value is very expensive to calculate or
  generally difficult to setup and teardown again.
  
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
  @spec put_new_lazy(store, key, (() -> value)) :: store | no_return
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    case GenServer.call(store, {:put_new_lazy, key, fun}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  # TODO:
  # split(store, keys)
  #   Takes all entries corresponding to the given keys and extracts them into a map
    
  # TODO:
  # take(store, keys)
  #   Takes all entries corresponding to the given keys and returns them in a map
  
  @doc """
  Updates the `key` in `store` with the given function.
  
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
  @spec update(store, key, value, (value -> value)) :: store | no_return
  def update(store, key, initial, fun) do
    case GenServer.call(store, {:update, key, initial, fun}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
  @doc """
  Updates the `key` with the given function.
  
  If the `key` does not exist, raises `KeyError`.
  
  ## Examples
  
      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.update!(store, :a, &(&1 * 2))
      iex> Mnemonix.get(store, :a)
      2
      iex> Mnemonix.update!(store, :b, &(&1 * 2))
      ** (KeyError) key :b not found in: Mnemonix.Map.Store
  """
  @spec update!(store, key, (value -> value)) :: store | no_return
  def update!(store, key, fun) do
    case GenServer.call(store, {:update!, key, fun}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end
  
end
