defmodule Mnemonix.Store.Expiry.API do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc """
      Sets the entry under `key` to expire in `ttl` milliseconds.

      If the `key` does not exist, the contents of `store` will be unaffected.

      If the entry under `key` was already set to expire, the new `ttl` will be used instead.

      ## Examples

          iex> store = Mnemonix.new(%{a: 1})
          iex> Mnemonix.expires(store, :a, 1000)
          iex> :timer.sleep(1001)
          iex> Mnemonix.get(store, :a)
          nil

          iex> store = Mnemonix.new(%{a: 1})
          iex> Mnemonix.expires(store, :a, 24 * 60 * 60 * 1000)
          iex> Mnemonix.expires(store, :a, 1000)
          iex> :timer.sleep(1001)
          iex> Mnemonix.get(store, :a)
          nil
      """
      @spec expires(store, key, ttl) :: store | no_return
      def expires(store, key, ttl) do
        case GenServer.call(store, {:expires, key, ttl}) do
          :ok                  -> store
          {:raise, type, args} -> raise type, args
        end
      end

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
      @spec persist(store, key) :: store | no_return
      def persist(store, key) do
        case GenServer.call(store, {:persist, key}) do
          :ok                  -> store
          {:raise, type, args} -> raise type, args
        end
      end

    end
  end

end
