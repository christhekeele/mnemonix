defmodule Mnemonix.ETS.Store do
  @moduledoc """
  A `Mnemonix.Store` adapter that uses an ETS table to store state.

      iex> {:ok, store} = Mnemonix.ETS.Store.start_link
      iex> Mnemonix.put(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.delete(store, :foo)
      iex> Mnemonix.get(store, :foo)
      nil
  """

  use Mnemonix.Store.Behaviour

  alias Mnemonix.Store
  alias Mnemonix.ETS.Exception

  @typep store  :: Store.t
  @typep opts   :: Store.opts
  @typep state  :: Store.state
  @typep key    :: Store.key
  @typep value  :: Store.value
  # @typep ttl    :: Store.ttl # TODO: expiry

  @doc """
  Creates a new ETS table to store state.

  ## Options

  - `table:` Name of the table to create.

    *Default:* `#{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}.Table`

  - `named:` ETS named table option

    *Default:* `false`

    If making a non-public table it's reccommened to use this option, so that
    the table name can be used outside of this store.

  - `privacy:` ETS privacy option - `:public | :protected | :private`

    *Default:* `:private`

  - `heir:` ETS heir option - `{pid, any} | nil`

    *Default:* nil

  - `transactional`: Whether or not to perform transactional reads or writes.

    *Allowed:* `:reads | :writes | :both | nil`

    *Default:* `nil`

  - `compressed`: Whether or not to compress the values being stored.

    *Default:* `false`
  """
  @spec init(opts) :: {:ok, state} | {:stop, reason :: any}
  def init(opts) do
    table   = Keyword.get(opts, :table) || Module.concat(__MODULE__, Table)
    privacy = Keyword.get(opts, :privacy) || :private
    heir    = Keyword.get(opts, :heir) || :none
    read    = not Keyword.get(opts, :transactional, :both) in [:reads, :both]
    write   = not Keyword.get(opts, :transactional, :both) in [:writes, :both]

    options = [:set, privacy,
      heir: heir,
      read_concurrency: read,
      write_concurrency: write
    ]

    options = if Keyword.get(opts, :named) do
      [:named_table | options]
    else
      options
    end

    options = if Keyword.get(opts, :compressed) do
      [:compressed | options]
    else
      options
    end

    case :ets.new(table, options) do
      {:error, reason} -> {:stop, reason}
      state            -> {:ok, state}
    end
  end

  @spec delete(store, key) :: {:ok, store}
  def delete(store = %Store{state: table}, key) do
    if :ets.delete(table, key) do
      {:ok, store}
    else
      {:raise, Exception,
        "ETS operation failed: `:ets.delete(#{table}, #{key})`"
      }
    end
  end

  # TODO: expiry
  # @spec expires(store, key, ttl) :: {:ok, store}
  # def expires(store = %Store{state: state}, key, ttl) do
  #   {:ok, store}
  # end

  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
  def fetch(store = %Store{state: table}, key) do
    case :ets.lookup(table, key) do
      [{^key, value} | []] -> {:ok, store, {:ok, value}}
      []                   -> {:ok, store, :error}
      other                -> {:raise, Exception, other}
    end
  end

  @spec put(store, key, Store.value) :: {:ok, store}
  def put(store = %Store{state: table}, key, value) do
    if :ets.insert(table, {key, value}) do
      {:ok, store}
    else
      {:raise, Exception,
        "ETS operation failed: `:ets.insert(#{table}, {#{key}, #{value}})`"
      }
    end
  end

end
