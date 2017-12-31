defmodule Mnemonix.Features.Expiry do
  @name Inspect.inspect(__MODULE__, %Inspect.Opts{})

  @moduledoc """
  Functions to manage the time-to-live of entries within a store.

  Using this feature will define all of its Mnemonix client API functions on your module.
  Refer to `Mnemonix.Builder` for documentation on options you can use when doing so.
  """

  use Mnemonix.Behaviour
  use Mnemonix.Singleton.Behaviour

  @typedoc """
  The number of milliseconds an entry will be allowed to be retrieved.
  """
  @type ttl :: non_neg_integer | nil

  @callback expire(Mnemonix.store, Mnemonix.key, ttl)
    :: Mnemonix.store | no_return
  @doc """
  Sets the entry under `key` to expire in `ttl` milliseconds.

  If the `key` does not exist, the contents of `store` will be unaffected.

  If the entry under `key` was already set to expire, the new `ttl` will be used instead.

  If the `ttl` is `nil` or not provided, it will defer to the `ttl` passed into the store's options.
  If that was also `nil`, the entry will not be set to expire.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> #{@name}.expire(store, :a, 1)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil

      iex> store = Mnemonix.new(%{a: 1})
      iex> #{@name}.expire(store, :a, 24 * 60 * 60 * 1)
      iex> #{@name}.expire(store, :a, 1)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil

      iex> store = Mnemonix.new(%{a: 1})
      iex> #{@name}.expire(store, :a, 1)
      iex> #{@name}.expire(store, :a, 24 * 60 * 60 * 1)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      1
  """
  @spec expire(Mnemonix.store, Mnemonix.key, ttl)
    :: Mnemonix.store | no_return
  def expire(store, key, ttl) do
    case GenServer.call(store, {:expire, key, ttl}) do
      :ok -> store
      {:warn, message} -> with :ok <- IO.warn(message), do: store
      {:raise, type, args} -> raise type, args
    end
  end

  @callback persist(Mnemonix.store, Mnemonix.key)
    :: Mnemonix.store | no_return
  @doc """
  Prevents the entry under `key` from expiring.

  If the `key` does not exist or is not set to expire, the contents of `store` will be unaffected.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expire(store, :a, 200)
      iex> #{@name}.persist(store, :a)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      1
  """
  @spec persist(Mnemonix.store, Mnemonix.key)
    :: Mnemonix.store | no_return
  def persist(store, key) do
    case GenServer.call(store, {:persist, key}) do
      :ok -> store
      {:warn, message} -> with :ok <- IO.warn(message), do: store
      {:raise, type, args} -> raise type, args
    end
  end

  @callback put_and_expire(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.store | no_return
  @doc """
  Creates a new entry for `value` under `key` in `store`
  and sets it to expire.

  It will use the `ttl` passed into the store's options.
  If that was not set, the entry will not be set to expire.

  ## Examples

      iex> store = Mnemonix.new
      iex> #{@name}.put_and_expire(store, :a, "bar", 1)
      iex> Mnemonix.get(store, :a)
      "bar"
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @spec put_and_expire(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.store | no_return
  def put_and_expire(store, key, value), do: put_and_expire(store, key, value, nil)

  @callback put_and_expire(Mnemonix.store, Mnemonix.key, Mnemonix.value, ttl)
    :: Mnemonix.store | no_return
  @doc """
  Creates a new entry for `value` under `key` in `store`
  and sets it to expire in `ttl` milliseconds.

  If the `ttl` is `nil` or not provided, it will defer to the `ttl` passed into the store's options.
  If that was also `nil`, the entry will not be set to expire.

  ## Examples

      iex> store = Mnemonix.new
      iex> #{@name}.put_and_expire(store, :a, "bar", 1)
      iex> Mnemonix.get(store, :a)
      "bar"
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @spec put_and_expire(Mnemonix.store, Mnemonix.key, Mnemonix.value, ttl)
    :: Mnemonix.store | no_return
  def put_and_expire(store, key, value, ttl) do
    case GenServer.call(store, {:put_and_expire, key, value, ttl}) do
      :ok -> store
      {:warn, message} -> with :ok <- IO.warn(message), do: store
      {:raise, type, args} -> raise type, args
    end
  end
end
