defmodule Mnemonix.Features.Bump do
  @moduledoc """
  Functions to increment/decrement integer values within a store.

  Using this feature will define all of its Mnemonix client API functions on your module.
  Refer to `Mnemonix.Builder` for documentation on options you can use when doing so.
  """

  use Mnemonix.Behaviour
  use Mnemonix.Singleton.Behaviour

  @typedoc """
  The target of a bump operation.
  """
  @type value :: integer

  @typedoc """
  The amount of a bump operation.
  """
  @type amount :: integer

  @typedoc """
  The return value of a bump operation.
  """
  @type result :: value | {:error, :no_integer}

  @callback bump(Mnemonix.store(), Mnemonix.key(), amount) :: result | no_return
  @doc """
  Adds `amount` to the value of the integer entry under `key` in `store`.

  If an entry for `key` does not exist,
  it is set to `0` before performing the operation.

  If the `amount` or the value under `key` is not an integer,
  returns `{:error, :no_integer}`, otherwise returns `:ok`,
  and the value will remain unchanged.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.Features.Bump.bump(store, :a, 1)
      2

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.bump(store, :b, 2)
      2

      iex> store = Mnemonix.new(%{c: "foo"})
      iex> Mnemonix.Features.Bump.bump(store, :c, 3)
      {:error, :no_integer}
      iex> Mnemonix.get(store, :c)
      "foo"

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.bump(store, :c, "foo")
      {:error, :no_integer}
      iex> Mnemonix.get(store, :d)
      nil
  """
  @spec bump(Mnemonix.store(), Mnemonix.key(), amount) :: result | no_return
  def bump(store, key, amount) do
    case GenServer.call(store, {:bump, key, amount}) do
      {:ok, value} -> value
      {:error, :no_integer} -> {:error, :no_integer}
      {:raise, type, args} -> raise type, args
    end
  end

  @callback bump!(Mnemonix.store(), Mnemonix.key(), amount) :: Mnemonix.store() | no_return
  @doc """
  Adds `amount` to the value of the integer entry under `key` in `store`.

  If an entry for `key` does not exist,
  it is set to `0` before performing the operation.

  If the `amount` or the value under `key` is not an integer, raises an `ArithmeticError`,
  and the value will remain unchanged. Otherwise, returns the `store`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.Features.Bump.bump!(store, :a, 2)
      iex> Mnemonix.get(store, :a)
      3

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.bump!(store, :b, 2)
      iex> Mnemonix.get(store, :b)
      2

      iex> store = Mnemonix.new(%{c: "foo"})
      iex> Mnemonix.Features.Bump.bump!(store, :c, 2)
      ** (ArithmeticError) bad argument in arithmetic expression

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.bump!(store, :d, "foo")
      ** (ArithmeticError) bad argument in arithmetic expression
  """
  @spec bump!(Mnemonix.store(), Mnemonix.key(), amount) :: :ok | no_return
  def bump!(store, key, amount) do
    case GenServer.call(store, {:bump!, key, amount}) do
      :ok -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @callback increment(Mnemonix.store(), Mnemonix.key()) :: Mnemonix.store() | no_return
  @doc """
  Increments the value of the integer entry under `key` in `store` by `1`.

  If an entry for `key` does not exist,
  it is set to `0` before performing the operation.

  If the value under `key` is not an integer,
  the store remains unchanged and `{:error, :no_integer}` is returned.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.Features.Bump.increment(store, :a)
      2

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.increment(store, :b)
      1

      iex> store = Mnemonix.new(%{c: "foo"})
      iex> Mnemonix.Features.Bump.increment(store, :c)
      {:error, :no_integer}
      iex> Mnemonix.get(store, :c)
      "foo"
  """
  @spec increment(Mnemonix.store(), Mnemonix.key()) :: Mnemonix.store() | no_return
  def increment(store, key) do
    case GenServer.call(store, {:increment, key}) do
      {:ok, value} -> value
      {:error, :no_integer} -> {:error, :no_integer}
      {:raise, type, args} -> raise type, args
    end
  end

  @callback increment(Mnemonix.store(), Mnemonix.key(), amount) ::
              Mnemonix.store() | no_return
  @doc """
  Increments the value of the integer entry under `key` in `store` by `amount`.

  If an entry for `key` does not exist,
  it is set to `0` before performing the operation.

  If the `amount` or the value under `key` is not an integer,
  the store remains unchanged and `{:error, :no_integer}` is returned.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.Features.Bump.increment(store, :a, 2)
      3

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.increment(store, :b, 2)
      2

      iex> store = Mnemonix.new(%{c: "foo"})
      iex> Mnemonix.Features.Bump.increment(store, :c, 2)
      {:error, :no_integer}
      iex> Mnemonix.get(store, :c)
      "foo"

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.increment(store, :d, "foo")
      {:error, :no_integer}
      iex> Mnemonix.get(store, :d)
      nil
  """
  @spec increment(Mnemonix.store(), Mnemonix.key(), amount) ::
          Mnemonix.store() | no_return
  def increment(store, key, amount) do
    case GenServer.call(store, {:increment, key, amount}) do
      {:ok, value} -> value
      {:error, :no_integer} -> {:error, :no_integer}
      {:raise, type, args} -> raise type, args
    end
  end

  @callback decrement(Mnemonix.store(), Mnemonix.key()) :: Mnemonix.store() | no_return
  @doc """
  Decrements the value of the integer entry under `key` in `store` by `1`.

  If an entry for `key` does not exist,
  it is set to `0` before performing the operation.

  If the value under `key` is not an integer,
  the store remains unchanged and `{:error, :no_integer}` is returned.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.Features.Bump.decrement(store, :a)
      0

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.decrement(store, :b)
      -1

      iex> store = Mnemonix.new(%{c: "foo"})
      iex> Mnemonix.Features.Bump.decrement(store, :c)
      {:error, :no_integer}
      iex> Mnemonix.get(store, :c)
      "foo"
  """
  @spec decrement(Mnemonix.store(), Mnemonix.key()) :: Mnemonix.store() | no_return
  def decrement(store, key) do
    case GenServer.call(store, {:decrement, key}) do
      {:ok, value} -> value
      {:error, :no_integer} -> {:error, :no_integer}
      {:raise, type, args} -> raise type, args
    end
  end

  @callback decrement(Mnemonix.store(), Mnemonix.key(), amount) ::
              Mnemonix.store() | no_return
  @doc """
  Decrements the value of the integer entry under `key` in `store` by `amount`.

  If an entry for `key` does not exist,
  it is set to `0` before performing the operation.

  If `amount` or the value under `key` is not an integer,
  the store remains unchanged and `{:error, :no_integer}` is returned.

  ## Examples

      iex> store = Mnemonix.new(%{a: 2})
      iex> Mnemonix.Features.Bump.decrement(store, :a, 2)
      0

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.decrement(store, :b, 2)
      -2

      iex> store = Mnemonix.new(%{c: "foo"})
      iex> Mnemonix.Features.Bump.decrement(store, :c, 2)
      {:error, :no_integer}
      iex> Mnemonix.get(store, :c)
      "foo"

      iex> store = Mnemonix.new
      iex> Mnemonix.Features.Bump.decrement(store, :d, "foo")
      {:error, :no_integer}
      iex> Mnemonix.get(store, :d)
      nil
  """
  @spec decrement(Mnemonix.store(), Mnemonix.key(), amount) ::
          Mnemonix.store() | no_return
  def decrement(store, key, amount) do
    case GenServer.call(store, {:decrement, key, amount}) do
      {:ok, value} -> value
      {:error, :no_integer} -> {:error, :no_integer}
      {:raise, type, args} -> raise type, args
    end
  end
end
