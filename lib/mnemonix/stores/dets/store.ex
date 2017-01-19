defmodule Mnemonix.Stores.DETS do
  @moduledoc """
  A `Mnemonix.Store` module that uses a DETS table to store state.

      iex> {:ok, store} = Mnemonix.Stores.DETS.start_link
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
  alias Mnemonix.DETS.Exception

  @doc """
  Creates a new DETS table to store state.

  If the DETS file already exists, will use the contents of that table.

  ## Options

  - `table:` Name of the table to connect to.

    *Default:* `#{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}.Table`

  The rest of the options are passed into `:dets.open_file/2` verbaitm, except
  for `type:`, which will always be `:set`.
  """
  @spec setup(opts) :: {:ok, state} | {:stop, reason :: any}
  def setup(opts) do
    {table, opts} = Keyword.get_and_update(opts, :table, fn _ -> :pop end)
    table = if table, do: table, else: Module.concat(__MODULE__, Table)

    with {:error, reason} <- :dets.open_file(table, opts) do
      {:stop, reason}
    end
  end

  @spec delete(store, key) :: {:ok, store} | exception
  def delete(store = %Store{state: table}, key) do
    if :dets.delete(table, key) do
      {:ok, store}
    else
      {:raise, Exception,
        "DETS operation failed: `:dets.delete(#{table}, #{key})`"
      }
    end
  end

  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error} | exception
  def fetch(store = %Store{state: table}, key) do
    case :dets.lookup(table, key) do
      [{^key, value} | []] -> {:ok, store, {:ok, value}}
      []                   -> {:ok, store, :error}
      other                -> {:raise, Exception, other}
    end
  end

  @spec put(store, key, Store.value) :: {:ok, store} | exception
  def put(store = %Store{state: table}, key, value) do
    if :dets.insert(table, {key, value}) do
      {:ok, store}
    else
      {:raise, Exception,
        "DETS operation failed: `:dets.insert(#{table}, {#{key}, #{value}})`"
      }
    end
  end

  @spec teardown(reason, store) :: {:ok, reason} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

  def teardown(reason, %Store{state: state}) do
    with :ok <- :dets.close(state) do
      {:ok, reason}
    end
  end

end
