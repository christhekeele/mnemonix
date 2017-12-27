if Code.ensure_loaded?(Redix) do
  defmodule Mnemonix.Stores.Redix do
    @moduledoc """
    A `Mnemonix.Store` that uses Redix to store state in redis.

        iex> {:ok, store} = Mnemonix.Stores.Redix.start_link
        iex> Mnemonix.put(store, "foo", "bar")
        iex> Mnemonix.get(store, "foo")
        "bar"
        iex> Mnemonix.delete(store, "foo")
        iex> Mnemonix.get(store, "foo")
        nil

    This store supports the functions in `Mnemonix.Features.Enumerable`.
    """

    alias Mnemonix.Store
    alias Mnemonix.Store.Server

    use Store.Behaviour
    use Store.Translator.Term

    defmodule Exception do
      defexception [:message]
    end

    ####
    # Mnemonix.Store.Behaviours.Core
    ##

    @doc """
    Connects to redis to store data using provided `opts`.

    ## Options

    - `conn:` The Redis to connect to, as either a string or list of opts w/ host, port, password, and database.

      - *Default:* `"redis://localhost:6379"`

    - `initial:` A map of key/value pairs to ensure are set in redis at boot.

      - *Default:* `%{}`

    All other options are passed verbatim to `Redix.start_link/2`.
    """
    @impl Store.Behaviours.Core
    @spec setup(Store.options()) :: {:ok, state :: term} | :ignore | {:stop, reason :: term}
    def setup(opts) do
      {conn, options} = Keyword.get_and_update(opts, :conn, fn _ -> :pop end)

      Redix.start_link(conn || "redis://localhost:6379", options)
    end

    ####
    # Mnemonix.Store.Behaviours.Map
    ##

    @impl Store.Behaviours.Map
    @spec delete(Store.t(), Mnemonix.key()) :: Server.instruction()
    def delete(%Store{state: conn} = store, key) do
      case Redix.command(conn, ~w[DEL #{key}]) do
        {:ok, 1} -> {:ok, store}
        {:error, reason} -> {:raise, store, Exception, [reason: reason]}
      end
    end

    @impl Store.Behaviours.Map
    @spec fetch(Store.t(), Mnemonix.key()) :: Server.instruction({:ok, Mnemonix.value()} | :error)
    def fetch(%Store{state: conn} = store, key) do
      case Redix.command(conn, ~w[GET #{key}]) do
        {:ok, nil} -> {:ok, store, :error}
        {:ok, value} -> {:ok, store, {:ok, value}}
        {:error, reason} -> {:raise, store, Exception, [reason: reason]}
      end
    end

    @impl Store.Behaviours.Map
    @spec put(Store.t(), Mnemonix.key(), Mnemonix.value()) :: Server.instruction()
    def put(%Store{state: conn} = store, key, value) do
      case Redix.command(conn, ~w[SET #{key} #{value}]) do
        {:ok, "OK"} -> {:ok, store}
        {:error, reason} -> {:raise, store, Exception, [reason: reason]}
      end
    end

    ####
    # Mnemonix.Store.Behaviours.Enumerable
    ##

    @doc """
    Returns `true`: this store supports the functions in `Mnemonix.Features.Enumerable`.
    """
    @impl Store.Behaviours.Enumerable
    @spec enumerable?(Store.t()) :: Server.instruction(boolean)
    def enumerable?(%Store{} = store) do
      {:ok, store, true}
    end

    @impl Store.Behaviours.Enumerable
    @spec to_enumerable(Store.t()) :: Server.instruction([Mnemonix.pair()])
    def to_enumerable(%Store{} = store) do
      to_list(store)
    end

    # Overrides

    @impl Store.Behaviours.Enumerable
    @spec keys(Store.t()) :: Server.instruction([Mnemonix.key()])
    def keys(%Store{state: conn} = store) do
      case Redix.command(conn, ~w[KEYS *]) do
        {:ok, keys} -> {:ok, store, keys}
        {:error, reason} -> {:raise, store, Exception, [reason: reason]}
      end
    end

    @impl Store.Behaviours.Enumerable
    @spec to_list(Store.t()) :: Server.instruction([Mnemonix.pair()])
    def to_list(%Store{} = store) do
      with {:ok, %Store{state: conn} = store, keys} <- keys(store) do
        case Redix.command(conn, ["MGET" | keys]) do
          {:ok, values} -> {:ok, store, Enum.zip(keys, values)}
          {:error, reason} -> {:raise, store, Exception, [reason: reason]}
        end
      end
    end

    @impl Store.Behaviours.Enumerable
    @spec values(Store.t()) :: Server.instruction([Mnemonix.key()])
    def values(%Store{} = store) do
      with {:ok, %Store{state: conn} = store, keys} <- keys(store) do
        case Redix.command(conn, ["MGET" | keys]) do
          {:ok, values} -> {:ok, store, values}
          {:error, reason} -> {:raise, store, Exception, [reason: reason]}
        end
      end
    end

    ####
    # Enumerable Protocol Overrides
    ##

    @impl Store.Behaviours.Enumerable
    @spec enumerable_count(Store.t()) :: Server.instruction(non_neg_integer)
    def enumerable_count(%Store{state: conn} = store) do
      case Redix.command(conn, ["DBSIZE"]) do
        {:ok, count} -> {:ok, store, count}
        {:error, reason} -> {:raise, store, Exception, [reason: reason]}
      end
    end
  end
end
