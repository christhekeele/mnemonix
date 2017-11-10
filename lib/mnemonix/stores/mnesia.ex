defmodule Mnemonix.Stores.Mnesia do
  @moduledoc """
  A `Mnemonix.Store` that uses a Mnesia table to store state.

  Before using, your current node should be part of a Mnesia schema
  and the Mnesia application must have been started.

      iex> {:ok, store} = Mnemonix.Stores.Mnesia.start_link
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
  use Store.Translator.Raw

  defmodule Exception do
    defexception [:message]
  end

####
# Mnemonix.Store.Behaviours.Core
##

  @doc """
  Creates a Mnesia table to store state in using provided `opts`.

  If the table specified already exists, it will use that instead.

  ## Options

  - `table:` Name of the table to use, will be created if it doesn't exist.

    - *Default:* `#{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}.Table`

  - `transactional`: Whether or not to perform transactional reads or writes.

    - *Allowed:* `:reads | :writes | :both | nil`

    - *Default:* `:both`

  - `initial:` A map of key/value pairs to ensure are set on the table at boot.

    - *Default:* `%{}`

  The rest of the options are passed into `:dets.open_file/2` verbaitm, except
  for `type:`, which will always be `:set`.
  """
  @impl Store.Behaviours.Core
  @spec setup(Store.options)
    :: {:ok, state :: term} | {:stop, reason :: any}
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

####
# Mnemonix.Store.Behaviours.Map
##

  @impl Store.Behaviours.Map
  @spec delete(Store.t, Mnemonix.key)
    :: {:ok, Store.t} | Store.Behaviour.exception
  def delete(store = %Store{state: table}, key) do
    with :ok <- :mnesia.dirty_delete(table, key) do
      {:ok, store}
    end
  end

  @impl Store.Behaviours.Map
  @spec fetch(Store.t, Mnemonix.key)
    :: {:ok, Store.t, {:ok, Mnemonix.value} | :error} | Store.Behaviour.exception
  def fetch(store = %Store{state: table}, key) do
    case :mnesia.dirty_read(table, key) do
      [{^table, ^key, value} | []] -> {:ok, store, {:ok, value}}
      []                           -> {:ok, store, :error}
      other                        -> {:raise, Exception, [reason: other]}
    end
  end

  @impl Store.Behaviours.Map
  @spec put(Store.t, Mnemonix.key, Store.value)
    :: {:ok, Store.t} | Store.Behaviour.exception
  def put(store = %Store{state: table}, key, value) do
    with :ok <- :mnesia.dirty_write({table, key, value}) do
      {:ok, store}
    end
  end

end
