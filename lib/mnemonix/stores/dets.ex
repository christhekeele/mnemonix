defmodule Mnemonix.Stores.DETS do
  @moduledoc """
  A `Mnemonix.Store` that uses a DETS table to store state.

      iex> {:ok, store} = Mnemonix.Stores.DETS.start_link
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

    def exception(opts) do
      %__MODULE__{message: if Keyword.has_key?(opts, :reason) do
        "ets operation failed for reason: `#{Keyword.get(opts, :reason)}`"
      else
        "ets operation failed"
      end}
    end
  end

####
# Mnemonix.Store.Behaviours.Core
##

  @doc """
  Creates a new DETS table to store state using provided `opts`.

  If the DETS file already exists, will use the contents of that table.

  ## Options

  - `table:` Name of the table to connect to.

    - *Default:* `#{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}.Table`

  - `initial:` A map of key/value pairs to ensure are set on the ETS table at boot.

    - *Default:* `%{}`

  The rest of the options are passed into `:dets.open_file/2` verbaitm, except
  for `type:`, which will always be `:set`.
  """
  @impl Store.Behaviours.Core
  @spec setup(Store.options)
    :: {:ok, state :: term} | {:stop, reason :: any}
  def setup(opts) do
    {table, opts} = Keyword.pop(opts, :table)
    table = if table, do: table, else: Module.concat(__MODULE__, Table)

    with {:error, reason} <- :dets.open_file(table, opts) do
      {:stop, reason}
    end
  end

  @impl Store.Behaviours.Core
  @spec teardown(reason, Store.t)
    :: {:ok, reason} | {:error, reason}
      when reason: :normal | :shutdown | {:shutdown, term} | term
  def teardown(reason, %Store{state: state}) do
    with :ok <- :dets.close(state) do
      {:ok, reason}
    end
  end

####
# Mnemonix.Store.Behaviours.Map
##

  @impl Store.Behaviours.Map
  @spec delete(Store.t, Mnemonix.key)
    :: Store.Server.instruction(:ok)
  def delete(store = %Store{state: table}, key) do
    :dets.delete(table, key)
    {:ok, store, :ok}
  end

  @impl Store.Behaviours.Map
  @spec fetch(Store.t, Mnemonix.key)
    :: Store.Server.instruction({:ok, Mnemonix.value} | :error)
  def fetch(store = %Store{state: table}, key) do
    case :dets.lookup(table, key) do
      [{^key, value} | []] -> {:ok, store, {:ok, value}}
      []                   -> {:ok, store, :error}
      other                -> {:raise, Exception, other}
    end
  end

  @impl Store.Behaviours.Map
  @spec put(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction(:ok)
  def put(store = %Store{state: table}, key, value) do
    :dets.insert(table, {key, value})
    {:ok, store, :ok}
  end

end
