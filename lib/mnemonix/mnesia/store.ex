defmodule Mnemonix.Mnesia.Store do
  @moduledoc """
  A `Mnemonix.Store` adapter that uses a Mnesia table to store state.

  Before using, you must have started Mnesia:

      iex> :mnesia.create_schema([node])
      iex> :mnesia.start()
      :ok
      iex> {:ok, store} = Mnemonix.Mnesia.Store.start_link
      iex> Mnemonix.put(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.delete(store, :foo)
      iex> Mnemonix.get(store, :foo)
      nil
  """

  use Mnemonix.Store

  alias Mnemonix.Store
  alias Mnemonix.Mnesia.Exception

  @typep store  :: Store.t
  @typep opts   :: Store.opts
  @typep state  :: Store.state
  @typep key    :: Store.key
  @typep value  :: Store.value
  # @typep ttl    :: Store.ttl # TODO: expiry

  @doc """
  Creates a Mnesia table to store state in.

  If the table specified already exists, it will use that instead.

  ## Options

  - `table:` Name of the table to use, will be created if it doesn't exist.
    *Default:* `#{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}.Table`

  - `transactional`: Whether or not to perform transactional reads or writes.
    *Allowed:* `:reads | :writes | :both | nil`
    *Default:* `:both`

  The rest of the options are passed into `:dets.open_file/2` verbaitm, except
  for `type:`, which will always be `:set`.
  """
  @spec init(opts) :: {:ok, state} | {:stop, reason :: any}
  def init(opts) do
    {table, opts} = Keyword.get_and_update(opts, :table, fn _ -> :pop end)
    table = if table, do: table, else: Module.concat(__MODULE__, Table)

    options = opts
    |> Keyword.put(:type, :set)
    |> Keyword.put(:attributes, [:key, :value])

    case :mnesia.create_table(table, options) do
      {:atomic, :ok} -> {:ok, table}
      {:aborted, {:already_exists, ^table}} -> {:ok, table}
      {:aborted, reason} -> {:stop, reason}
    end
  end

  @spec delete(store, key) :: {:ok, store}
  def delete(store = %Store{state: table}, key) do
    with :ok <- :mnesia.dirty_delete(table, key) do
      {:ok, store}
    end
  end

  # TODO: expiry
  # @spec expires(store, key, ttl) :: {:ok, store}
  # def expires(store = %Store{state: state}, key, ttl) do
  #   {:ok, store}
  # end

  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
  def fetch(store = %Store{state: table}, key) do
    case :mnesia.dirty_read(table, key) do
      [{^table, ^key, value} | []] -> {:ok, store, {:ok, value}}
      []                           -> {:ok, store, :error}
      other                        -> {:raise, Exception, other}
    end
  end

  @spec put(store, key, Store.value) :: {:ok, store}
  def put(store = %Store{state: table}, key, value) do
    with :ok <- :mnesia.dirty_write({table, key, value}) do
      {:ok, store}
    end
  end

end
