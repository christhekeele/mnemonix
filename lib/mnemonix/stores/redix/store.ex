if Code.ensure_loaded?(Redix) do
  defmodule Mnemonix.Stores.Redix do
    @moduledoc """
    A `Mnemonix.Store` that uses Redix to store state in redis.

        iex> {:ok, store} = Mnemonix.Stores.Redix.start_link
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
    alias Mnemonix.Redix.Exception

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

    @spec delete(store, key) :: {:ok, store} | exception
    def delete(store = %Store{state: conn}, key) do
      case Redix.command(conn, ~w[DEL #{key}]) do
        {:ok, 1}         -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

    @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error} | exception
    def fetch(store = %Store{state: conn}, key) do
      case Redix.command(conn, ~w[GET #{key}]) do
        {:ok, nil}       -> {:ok, store, :error}
        {:ok, value}     -> {:ok, store, {:ok, value}}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

    @spec put(store, key, Store.value) :: {:ok, store} | exception
    def put(store = %Store{state: conn}, key, value) do
      case Redix.command(conn, ~w[SET #{key} #{value}]) do
        {:ok, "OK"}      -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

  end
end
