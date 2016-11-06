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

    alias Mnemonix.Store
    alias Mnemonix.Memcachex.Exception

    @typep store  :: Store.t
    @typep opts   :: Store.opts
    @typep state  :: Store.state
    @typep key    :: Store.key
    @typep value  :: Store.value
    # @typep ttl    :: Store.ttl # TODO: expiry

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

    @spec delete(store, key) :: {:ok, store}
    def delete(store = %Store{state: conn}, key) do
      case Memcache.delete(conn, key) do
        {:ok}            -> {:ok, store}
        {:error, reason} -> {:raise, Exception, reason}
      end
    end

    # TODO: expiry
    # @spec expires(store, key, ttl) :: {:ok, store}
    # def expires(store = %Store{state: state}, key, ttl) do
    #   {:ok, store}
    # end

    @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
    def fetch(store = %Store{state: conn}, key) do
      case Memcache.get(conn, key) do
        {:error, "Key not found"} -> {:ok, store, :error}
        {:ok, value}              -> {:ok, store, {:ok, value}}
        {:error, reason}          -> {:raise, Exception, reason}
      end
    end

    @spec put(store, key, Store.value) :: {:ok, store}
    def put(store = %Store{state: conn}, key, value) do
      case Memcache.set(conn, key, value) do
        {:ok}            -> {:ok, store}
        {:error, reason} -> {:raise, Exception, reason}
      end
    end

  end
end
