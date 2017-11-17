defmodule Mnemonix.Features.Enumerable do
  @moduledoc """
  Functions that rely on enumerating over all key/value pairs within a store.

  All of these functions are available on the main `Mnemonix` module. However, not all stores
  support exhaustive iteration. Consult your store's docs for more information.

  Stores that do not support enumeration will raise a `Mnemonix.Features.Enumerable.Error`
  when these functions are called. You can validate that a store is enumerable before you
  invoke enumerable functions via `enumerable?/1`.
  """ && false

  use Mnemonix.Behaviour
  use Mnemonix.Singleton.Behaviour

  defmodule Error do
    defexception [:message]

    def exception(args) do
      %__MODULE__{message: "#{args[:module] |> Inspect.inspect(%Inspect.Opts{})} cannot be exhaustively iterated over"}
    end
  end

  @callback enumerable?(Mnemonix.store)
    :: boolean | no_return
  @doc """
  Returns `true` if the `store` is enumerable.

  Stores that return `false` will raise a `Mnemonix.Features.Enumerable.Error` for other functions
  in this module.

  ## Examples

      iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.ETS)
      iex> Mnemonix.enumerable? store
      true

      iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.Memcachex)
      iex> Mnemonix.enumerable? store
      false
  """
  @spec enumerable?(Mnemonix.store)
    :: boolean | no_return
  def enumerable?(store) do
    case GenServer.call(store, :enumerable?) do
      {:ok, enumerable}    -> enumerable
      {:raise, type, args} -> raise type, args
    end
  end

  @callback equal?(Mnemonix.store, Mnemonix.store)
    :: boolean | no_return
  @doc """
  Checks that contents of stores `store1` and `store2` are equal.

  Two stores are considered to be equal if they contain the same keys and those keys contain the same values.

  ## Examples

      iex> Mnemonix.equal? Mnemonix.new(%{a: 1}), Mnemonix.new(%{a: 1})
      true

      iex> Mnemonix.equal? Mnemonix.new(%{a: 1}), Mnemonix.new(%{a: 2})
      false

      iex> Mnemonix.equal? Mnemonix.new(%{a: 1}), Mnemonix.new(%{b: 2})
      false

  ## Notes

  If `enumerable?/1` returns `false` for either store then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  Depending on the underlying store types this function may be very inefficient.
  """
  @spec equal?(Mnemonix.store, Mnemonix.store)
    :: boolean | no_return
  def equal?(store1, store2) do
    with  {:ok, result1} when not is_tuple(result1) <- GenServer.call(store1, :to_enumerable),
          {:ok, result2} when not is_tuple(result2) <- GenServer.call(store2, :to_enumerable) do
      result1 === result2
    else
      {:raise, type, args} -> raise type, args
    end
  end

  @callback keys(Mnemonix.store)
    :: [Mnemonix.key] | no_return
  @doc """
  Returns all keys in `store`.

  If `enumerable?/1` returns false then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  ## Examples

      iex> Mnemonix.keys Mnemonix.new(%{a: 1, b: 2})
      [:a, :b]

      iex> Mnemonix.keys Mnemonix.new
      []

  ## Notes

  If `enumerable?/1` returns false then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  Depending on the underlying store this function may be very inefficient.
  """
  @spec keys(Mnemonix.store)
    :: [Mnemonix.key] | no_return
  def keys(store) do
    case GenServer.call(store, :keys) do
      {:ok, keys}          -> keys
      {:raise, type, args} -> raise type, args
    end
  end

  @callback to_list(Mnemonix.store)
    :: [{Mnemonix.key, Mnemonix.value}] | no_return
  @doc """
  Returns all key/value pairs in `store` as a list of two-tuples.

  If `enumerable?/1` returns false then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  ## Examples

      iex> Mnemonix.to_list Mnemonix.new(%{a: 1, b: 2})
      [a: 1, b: 2]

      iex> Mnemonix.to_list Mnemonix.new(%{"foo" => "bar"})
      [{"foo", "bar"}]

      iex> Mnemonix.to_list Mnemonix.new
      []

      iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.Memcachex)
      iex> Mnemonix.to_list store
      ** (Mnemonix.Features.Enumerable.Error) Mnemonix.Stores.Memcachex cannot be exhaustively iterated over

  ## Notes

  If `enumerable?/1` returns false then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  Depending on the underlying store this function may be very inefficient.
  """
  @spec to_list(Mnemonix.store)
    :: [{Mnemonix.key, Mnemonix.value}] | no_return
  def to_list(store) do
    case GenServer.call(store, :to_list) do
      {:ok, list}          -> list
      {:raise, type, args} -> raise type, args
    end
  end

  @callback values(Mnemonix.store)
    :: [Mnemonix.value] | no_return
  @doc """
  Returns all values in `store`.

  If `enumerable?/1` returns false then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  ## Examples

      iex> Mnemonix.values Mnemonix.new(%{a: 1, b: 2})
      [1, 2]
      iex> Mnemonix.values Mnemonix.new
      []

  ## Notes

  If `enumerable?/1` returns false then this function will raise a `Mnemonix.Features.Enumerable.Error`.

  Depending on the underlying store this function may be very inefficient.
  """
  @spec values(Mnemonix.store)
    :: [Mnemonix.value] | no_return
  def values(store) do
    case GenServer.call(store, :values) do
      {:ok, values}        -> values
      {:raise, type, args} -> raise type, args
    end
  end

end
