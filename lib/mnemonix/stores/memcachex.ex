if Code.ensure_loaded?(Memcache) do
  defmodule Mnemonix.Stores.Memcachex do
    @moduledoc """
    A `Mnemonix.Store` that uses Memcachex to store state in memcached.

        iex> {:ok, store} = Mnemonix.Stores.Memcachex.start_link
        iex> Mnemonix.put(store, "foo", "bar")
        iex> Mnemonix.get(store, "foo")
        "bar"
        iex> Mnemonix.delete(store, "foo")
        iex> Mnemonix.get(store, "foo")
        nil

    This store raises errors on the functions in `Mnemonix.Features.Enumerable`.
    """

    alias Mnemonix.Store

    use Store.Behaviour
    use Store.Translator.Term

    defmodule Exception do
      defexception [:message]
    end

  ####
  # Mnemonix.Store.Behaviours.Core
  ##

    @doc """
    Connects to memcached to store data using provided `opts`.

  - `initial:` A map of key/value pairs to ensure are set in memcached at boot.

    - *Default:* `%{}`

    All other options are passed verbatim to `Memcache.start_link/1`.
    """
    @impl Store.Behaviours.Core
    @spec setup(Store.options)
      :: {:ok, state :: term} | {:stop, reason :: any}
    def setup(opts) do
      options = opts
      |> Keyword.put(:coder, Memcache.Coder.Erlang)

      Memcache.start_link(options)
    end

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  @impl Store.Behaviours.Map
    @spec delete(Store.t, Mnemonix.key)
      :: {:ok, Store.t} | Store.Behaviour.exception
    def delete(store = %Store{state: conn}, key) do
      case Memcache.delete(conn, key) do
        {:ok}            -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

    @impl Store.Behaviours.Map
    @spec fetch(Store.t, Mnemonix.key)
      :: {:ok, Store.t, {:ok, Mnemonix.value} | :error} | Store.Behaviour.exception
    def fetch(store = %Store{state: conn}, key) do
      case Memcache.get(conn, key) do
        {:error, "Key not found"} -> {:ok, store, :error}
        {:ok, value}              -> {:ok, store, {:ok, value}}
        {:error, reason}          -> {:raise, Exception, [reason: reason]}
      end
    end

    @impl Store.Behaviours.Map
    @spec put(Store.t, Mnemonix.key, Store.value)
      :: {:ok, Store.t} | Store.Behaviour.exception
    def put(store = %Store{state: conn}, key, value) do
      case Memcache.set(conn, key, value) do
        {:ok}            -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

  end
end
