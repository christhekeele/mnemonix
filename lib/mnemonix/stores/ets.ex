defmodule Mnemonix.Stores.ETS do
  @name Inspect.inspect(__MODULE__, %Inspect.Opts{})

  @moduledoc """
  A `Mnemonix.Store` that uses an ETS table to store state.

      iex> {:ok, store} = Mnemonix.Stores.ETS.start_link
      iex> Mnemonix.put(store, "foo", "bar")
      iex> Mnemonix.get(store, "foo")
      "bar"
      iex> Mnemonix.delete(store, "foo")
      iex> Mnemonix.get(store, "foo")
      nil

  This store supports the functions in `Mnemonix.Features.Enumerable`.
  """

  alias Mnemonix.Store

  use Store.Behaviour
  use Store.Translator.Raw

  defmodule Exception do
    defexception [:message]

    def exception(opts) do
      %__MODULE__{
        message:
          if Keyword.has_key?(opts, :reason) do
            "ets operation failed for reason: `#{Keyword.get(opts, :reason)}`"
          else
            "ets operation failed"
          end
      }
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Core
  ##

  @doc """
  Creates a new ETS table to store state using provided `opts`.

  ## Options

  - `table`: Name of the table to create.

    - *Default:* `#{@name}.Table`

  - `named`: ETS named table option

    - *Default:* `false`

    - *Notes:* If making a non-private table it's reccommened to give your table a name.

  - `privacy`: ETS privacy option - `:public | :protected | :private`

    - *Default:* `:private`

  - `heir`: ETS heir option - `{pid, any} | nil`

    - *Default:* nil

  - `concurrent`: Whether or not to optimize access for concurrent reads or writes.

    - *Allowed:* `:reads | :writes | :both | false`

    - *Default:* `false`

  - `compressed`: Whether or not to compress the values being stored.

    - *Default:* `false`

  - `initial`: A map of key/value pairs to ensure are set on the ETS table at boot.

    - *Default:* `%{}`
  """
  @impl Store.Behaviours.Core
  @spec setup(Store.options()) :: {:ok, state :: term} | :ignore | {:stop, reason :: term}
  def setup(opts) do
    table = Keyword.get(opts, :table) || Module.concat(__MODULE__, Table)
    privacy = Keyword.get(opts, :privacy) || :private
    heir = Keyword.get(opts, :heir) || :none
    read = Keyword.get(opts, :concurrent, false) in [:reads, :both]
    write = Keyword.get(opts, :concurrent, false) in [:writes, :both]

    options = [:set, privacy, heir: heir, read_concurrency: read, write_concurrency: write]

    options =
      if Keyword.get(opts, :named) do
        [:named_table | options]
      else
        options
      end

    options =
      if Keyword.get(opts, :compressed) do
        [:compressed | options]
      else
        options
      end

    with table <- :ets.new(table, options) do
      {:ok, table}
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  @impl Store.Behaviours.Map
  @spec delete(Store.t(), Mnemonix.key()) :: Store.Server.instruction()
  def delete(%Store{state: table} = store, key) do
    :ets.delete(table, key)
    {:ok, store}
  end

  @impl Store.Behaviours.Map
  @spec fetch(Store.t(), Mnemonix.key()) ::
          Store.Server.instruction({:ok, Mnemonix.value()} | :error)
  def fetch(%Store{state: table} = store, key) do
    case :ets.lookup(table, key) do
      [{^key, value} | []] -> {:ok, store, {:ok, value}}
      [] -> {:ok, store, :error}
      other -> {:raise, store, Exception, reason: other}
    end
  end

  @impl Store.Behaviours.Map
  @spec put(Store.t(), Mnemonix.key(), Mnemonix.value()) :: Store.Server.instruction()
  def put(%Store{state: table} = store, key, value) do
    :ets.insert(table, {key, value})
    {:ok, store}
  end

  ####
  # Mnemonix.Store.Behaviours.Enumerable
  ##

  @doc """
  Returns `true`: this store supports the functions in `Mnemonix.Features.Enumerable`.
  """
  @impl Store.Behaviours.Enumerable
  @spec enumerable?(Store.t()) :: Store.Server.instruction(boolean)
  def enumerable?(store) do
    {:ok, store, true}
  end

  @impl Store.Behaviours.Enumerable
  @spec to_enumerable(Store.t()) :: Store.Server.instruction([Mnemonix.pair()])
  def to_enumerable(%Store{state: table} = store) do
    {:ok, store, :ets.tab2list(table)}
  end
end
