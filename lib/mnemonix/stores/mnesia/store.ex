defmodule Mnemonix.Mnesia.Store do
  @moduledoc """
  A `Mnemonix.Store` module that uses a Mnesia table to store state.

  Before using, your current node should be part of a Mnesia schema
  and the Mnesia application must have been started:

      iex> :mnesia.create_schema([node])
      iex> {:ok, store} = Mnemonix.Mnesia.Store.start_link
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
  alias Mnemonix.Mnesia.Exception

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
  @spec setup(opts) :: {:ok, state} | {:stop, reason :: any}
  def setup(opts) do
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

  @spec delete(store, key) :: {:ok, store} | exception
  def delete(store = %Store{state: table}, key) do
    with :ok <- :mnesia.dirty_delete(table, key) do
      {:ok, store}
    end
  end

  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error} | exception
  def fetch(store = %Store{state: table}, key) do
    case :mnesia.dirty_read(table, key) do
      [{^table, ^key, value} | []] -> {:ok, store, {:ok, value}}
      []                           -> {:ok, store, :error}
      other                        -> {:raise, Exception, [reason: other]}
    end
  end

  @spec put(store, key, Store.value) :: {:ok, store} | exception
  def put(store = %Store{state: table}, key, value) do
    with :ok <- :mnesia.dirty_write({table, key, value}) do
      {:ok, store}
    end
  end

end
