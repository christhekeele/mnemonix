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

    This store throws errors on the functions in `Mnemonix.Features.Enumerable`.
    """

    defmodule Exception do
      defexception [:message]
    end

    use Mnemonix.Store.Behaviour
    use Mnemonix.Store.Translator.Term

    alias Mnemonix.Store

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
    @impl Mnemonix.Store.Behaviours.Core
    @spec setup(Mnemonix.Store.options)
      :: {:ok, state :: term} | {:stop, reason :: any}
    def setup(opts) do
      {conn, options} = Keyword.get_and_update(opts, :conn, fn _ -> :pop end)

      Redix.start_link(conn || "redis://localhost:6379", options)
    end

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  @impl Mnemonix.Store.Behaviours.Map
    @spec delete(Mnemonix.Store.t, Mnemonix.key)
      :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
    def delete(store = %Store{state: conn}, key) do
      case Redix.command(conn, ~w[DEL #{key}]) do
        {:ok, 1}         -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

    @impl Mnemonix.Store.Behaviours.Map
    @spec fetch(Mnemonix.Store.t, Mnemonix.key)
      :: {:ok, Mnemonix.Store.t, {:ok, Mnemonix.value} | :error} | Mnemonix.Store.Behaviour.exception
    def fetch(store = %Store{state: conn}, key) do
      case Redix.command(conn, ~w[GET #{key}]) do
        {:ok, nil}       -> {:ok, store, :error}
        {:ok, value}     -> {:ok, store, {:ok, value}}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

    @impl Mnemonix.Store.Behaviours.Map
    @spec put(Mnemonix.Store.t, Mnemonix.key, Store.value)
      :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
    def put(store = %Store{state: conn}, key, value) do
      case Redix.command(conn, ~w[SET #{key} #{value}]) do
        {:ok, "OK"}      -> {:ok, store}
        {:error, reason} -> {:raise, Exception, [reason: reason]}
      end
    end

  end
end
