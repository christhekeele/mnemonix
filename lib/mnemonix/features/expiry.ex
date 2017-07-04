defmodule Mnemonix.Features.Expiry do
  @moduledoc """
  Functions to manage the time-to-live of entries within a store.

  All of these functions are available on the main `Mnemonix` module.
  """

  defmacro __using__(opts) do
    quote do
      use Mnemonix.Feature, [unquote_splicing(opts), module: unquote(__MODULE__)]
    end
  end

  @typedoc """
  The number of milliseconds an entry will be allowed to be retreived.
  """
  @type ttl :: non_neg_integer | nil

  @doc """
  Sets the entry under `key` to expire in `ttl` milliseconds.

  If the `key` does not exist, the contents of `store` will be unaffected.

  If the entry under `key` was already set to expire, the new `ttl` will be used instead.

  If the `ttl` is `nil` or not provided, it will defer to the `ttl` passed into the store's options.
  If that was also `nil`, the entry will not be set to expire.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expire(store, :a, 1)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expire(store, :a, 24 * 60 * 60 * 1)
      iex> Mnemonix.expire(store, :a, 1)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @spec expire(Mnemonix.store, Mnemonix.key, ttl)
    :: Mnemonix.store | no_return
  def expire(store, key, ttl \\ nil) do
    case GenServer.call(store, {:expire, key, ttl}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Prevents the entry under `key` from expiring.

  If the `key` does not exist or is not set to expire, the contents of `store` will be unaffected.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expire(store, :a, 200)
      iex> Mnemonix.persist(store, :a)
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      1
  """
  @spec persist(Mnemonix.store, Mnemonix.key)
    :: Mnemonix.store | no_return
  def persist(store, key) do
    case GenServer.call(store, {:persist, key}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Creates a new entry for `value` under `key` in `store`
  and sets it to expire in `ttl` milliseconds.

  If the `ttl` is `nil` or not provided, it will defer to the `ttl` passed into the store's options.
  If that was also `nil`, the entry will not be set to expire.

  ## Examples

      iex> store = Mnemonix.new
      iex> Mnemonix.put_and_expire(store, :a, "bar", 1)
      iex> Mnemonix.get(store, :a)
      "bar"
      iex> :timer.sleep(200)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @spec put_and_expire(Mnemonix.store, Mnemonix.key, Mnemonix.value, ttl)
    :: Mnemonix.store | no_return
  def put_and_expire(store, key, value, ttl \\ nil) do
    case GenServer.call(store, {:put_and_expire, key, value, ttl}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

end
