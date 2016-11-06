defmodule Mnemonix.Store.Expiry.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Expiry.Functions
    end
  end

  alias Mnemonix.Store

  @typep store :: Store.t

  @typep key   :: Store.key
  @typep ttl   :: Store.ttl

  @typep exception :: Module.t
  @typep info      :: term


  ####
  # OPTIONAL
  ##

  @optional_callbacks setup_expiry: 1
  @doc """
  Prepares this store to track the expiration of its entries.
  """
  @callback setup_expiry(store) :: {:ok, store} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

  @optional_callbacks expires: 3
  @doc """
  Sets the entry under `key` to expire in `ttl` milliseconds.

  If the `key` does not exist, the contents of `store` will be unaffected.

  If the entry under `key` was already set to expire, the new `ttl` will be used instead.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expires(store, :a, 1)
      iex> :timer.sleep(100)
      iex> Mnemonix.get(store, :a)
      nil

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expires(store, :a, 24 * 60 * 60 * 1000)
      iex> Mnemonix.expires(store, :a, 1)
      iex> :timer.sleep(100)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @callback expires(store, key, ttl) :: {:ok, store} | {:raise, exception, info}

  @optional_callbacks persist: 2
  @doc """
  Prevents the entry under `key` from expiring.

  If the `key` does not exist or is not set to expire, the contents of `store` will be unaffected.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.expires(store, :a, 1000)
      iex> Mnemonix.persist(store, :a)
      iex> :timer.sleep(1001)
      iex> Mnemonix.get(store, :a)
      1
  """
  @callback persist(store, key) :: {:ok, store} | {:raise, exception, info}

end
