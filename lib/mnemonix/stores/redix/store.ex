if Code.ensure_loaded?(Redix) do
  defmodule Mnemonix.Redix.Store do
    @moduledoc """
    A `Mnemonix.Store` that uses Redix to store state in redis.

        iex> {:ok, store} = Mnemonix.Redix.Store.start_link
        iex> Mnemonix.put(store, :foo, "bar")
        iex> Mnemonix.get(store, :foo)
        "bar"
        iex> Mnemonix.delete(store, :foo)
        iex> Mnemonix.get(store, :foo)
        nil
    """

    use Mnemonix.Store.Behaviour

    alias Mnemonix.Store
    alias Mnemonix.Redix.Exception

    @typep store  :: Store.t
    @typep opts   :: Store.opts
    @typep state  :: Store.state
    @typep key    :: Store.key
    @typep value  :: Store.value
    # @typep ttl    :: Store.ttl # TODO: expiry

    @doc """
    Connects to redis to store data.

    ## Options

    - `conn:` The Redis to connect to, as either a string or list of opts w/ host, port, password, and database.

      *Default:* `"redis://localhost:6379"`

    All other options are passed verbatim to `Redix.start_link/2`.
    """
    @spec setup(opts) :: {:ok, state}
    def setup(opts) do
      {conn, options} = Keyword.get_and_update(opts, :conn, fn _ -> :pop end)

      Redix.start_link(conn || "redis://localhost:6379", options)
    end

    @spec delete(store, key) :: {:ok, store}
    def delete(store = %Store{state: conn}, key) do
      case Redix.command(conn, ~w[DEL #{key}]) do
        {:ok, 1}         -> {:ok, store}
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
      case Redix.command(conn, ~w[GET #{key}]) do
        {:ok, nil}       -> {:ok, store, :error}
        {:ok, value}     -> {:ok, store, {:ok, value}}
        {:error, reason} -> {:raise, Exception, reason}
      end
    end

    @spec put(store, key, Store.value) :: {:ok, store}
    def put(store = %Store{state: conn}, key, value) do
      case Redix.command(conn, ~w[SET #{key} #{value}]) do
        {:ok, "OK"}      -> {:ok, store}
        {:error, reason} -> {:raise, Exception, reason}
      end
    end

  end
end
