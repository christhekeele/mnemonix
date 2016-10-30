# defmodule Mnemonix.DETS.State do
#   defstruct data: %{}, expiry: %{}
# end

defmodule Mnemonix.DETS.Exception do
  defexception [:message]
end

defmodule Mnemonix.DETS.Store do
  @moduledoc """
  A `Mnemonix.Store` adapter that uses a DETS table to store state.
  
      iex> {:ok, store} = Mnemonix.DETS.Store.start_link
      iex> Mnemonix.put(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.delete(store, :foo)
      iex> Mnemonix.get(store, :foo)
      nil
  """
  
  use Mnemonix.Store
  alias Mnemonix.Store
  
  @typep store  :: Store.t
  @typep opts   :: Store.opts
  @typep state  :: Store.state
  @typep key    :: Store.key
  @typep value  :: Store.value
  # @typep ttl    :: Store.ttl # TODO: expiry
  
  @doc """
  Creates a new DETS table to store state.
  
  If the DETS file already exists, will use the contents of that table.
  
  ## Options
  
  - `table:` Name of the table to connect to.
    *Default:* `#{__MODULE__ |> IO.inspect}.Table`
    
  The rest of the options are passed into `:dets.open_file/2` verbaitm, except
  for `type:`, which will always be `:set`.
  """
  @spec init(opts) :: {:ok, state} | {:stop, reason :: any}
  def init(opts) do
    {table, opts} = Keyword.get_and_update(opts, :table, fn _ -> :pop end)
    
    with {:error, reason} <- :dets.open_file(table || Module.concat(__MODULE__, Table), opts) do
      {:stop, reason}
    end
  end
  
  @spec delete(store, key) :: {:ok, store}
  def delete(store = %Store{state: table}, key) do
    if :dets.delete(table, key) do
      {:ok, store}
    else
      {:raise, Mnemonix.DETS.Exception, "DETS operation failed: `:dets.delete(#{table}, #{key})`"}
    end
  end
  
  # TODO: expiry
  # @spec expires(store, key, ttl) :: {:ok, store}
  # def expires(store = %Store{state: state}, key, ttl) do
  #   {:ok, store}
  # end
  
  @spec fetch(store, key) :: {:ok, store, {:ok, value} | :error}
  def fetch(store = %Store{state: table}, key) do
    case :dets.lookup(table, key) do
      [{^key, value} | []] -> {:ok, store, {:ok, value}}
      []                   -> {:ok, store, :error}
      _                    -> {:raise, Mnemonix.DETS.Exception, "DETS operation failed: `:dets.lookup(#{table}, #{key})`"}
    end
  end
  
  @spec put(store, key, Store.value) :: {:ok, store}
  def put(store = %Store{state: table}, key, value) do
    if :dets.insert(table, {key, value}) do
      {:ok, store}
    else
      {:raise, Mnemonix.DETS.Exception, "DETS operation failed: `:dets.insert(#{table}, {#{key}, #{value}})`"}
    end
  end
  
  def teardown(reason, store = %Store{state: state}) do
    :dets.close state
  end
  
end