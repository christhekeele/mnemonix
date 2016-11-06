if Code.ensure_loaded?(Memcache) do
  defmodule Mnemonix.Memcachex.Store do
    @moduledoc """
    A `Mnemonix.Store` that uses Memcachex to store state in memcached.

        iex> {:ok, store} = Mnemonix.Memcachex.Store.start_link
        iex> Mnemonix.put(store, :foo, "bar")
        iex> Mnemonix.get(store, :foo)
        "bar"
        iex> Mnemonix.delete(store, :foo)
        iex> Mnemonix.get(store, :foo)
        nil
    """

    use Mnemonix.Store.Behaviour
    use Mnemonix.Store.Types, [:store, :opts, :state, :key, :value, :exception]

    alias Mnemonix.Store
    alias Mnemonix.Memcachex.Exception

    @doc """
    Connects to memcached to store data.

    All options are passed verbatim to `Memcache.start_link/1`.
    """
    @spec setup(opts) :: {:ok, state}
    def setup(opts) do
      options = opts
      |> Keyword.put(:coder, Memcache.Coder.Erlang)

      Memcache.start_link(options)
    end

    @spec delete(store, key) :: {:ok, store} | exception
    def delete(store = %Store{state: conn}, key) do
      case Memcache.delete(conn, key) do
        {:ok}            -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

    @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error} | exception
    def fetch(store = %Store{state: conn}, key) do
      case Memcache.get(conn, key) do
        {:error, "Key not found"} -> {:ok, store, :error}
        {:ok, value}              -> {:ok, store, {:ok, value}}
        {:error, reason}          -> {:raise, Exception, [reason: reason]}
      end
    end

    @spec put(store, key, Store.value) :: {:ok, store} | exception
    def put(store = %Store{state: conn}, key, value) do
      case Memcache.set(conn, key, value) do
        {:ok}            -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

  end
end
