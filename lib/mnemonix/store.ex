defmodule Mnemonix.Store do
  @moduledoc """
  Normalizes access to different key-value stores behind a `GenServer`.

  Once a store [has been started](#start_link/1), you can use `Mnemonix`
  methods to manipulate it:

      iex> Mnemonix.Store.start_link(Mnemonix.Map.Store, name: Store)
      iex> Mnemonix.put(Store, :foo, "bar")
      iex> Mnemonix.get(Store, :foo)
      "bar"
      iex> Mnemonix.delete(Store, :foo)
      iex> Mnemonix.get(Store, :foo)
      nil
  """

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type adapter :: Atom.t

  @typedoc """
  Options supplied to `c:Mnemonix.Store.Behaviour.init/1` to initialize
  the `t:adapter/0`.
  """
  @type opts :: Keyword.t

  @typedoc """
  Internal state specific to the `t:adapter/0`.
  """
  @type state :: term

  @typedoc """
  Container for `t:adapter/0`, `t:opts/0`, and `t:state/0`.
  """
  @type t :: %__MODULE__{adapter: adapter, opts: opts, state: state}
  @enforce_keys [:adapter]
  defstruct adapter: nil, opts: [], state: nil

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      use Mnemonix.Store.Behaviour
    end
  end

  @typedoc """
  Keys allowed in Mnemonix entries.
  """
  @type key   :: term

  @typedoc """
  Values allowed in Mnemonix entries.
  """
  @type value :: term

  # @typedoc """
  # The number of seconds an entry will be allowed to exist.
  # """
  # @type ttl   :: non_neg_integer | nil

  @typedoc """
  Adapter and optional initialization options for `start_link/1`.
  """
  @type init :: adapter | {adapter, opts}

  @doc """
  Starts a new `Mnemonix.Store` using `adapter`.

  If you wish to pass options to `GenServer.start_link/3`, use `start_link/2`.

  The returned `GenServer.on_start/0` reference can be used in
  the `Mnemonix` API.

  ## Examples

    iex> {:ok, store} = Mnemonix.Store.start_link(Mnemonix.Map.Store)
    iex> Mnemonix.put(store, :foo, :bar)
    iex> Mnemonix.get(store, :foo)
    :bar

    iex> {:ok, store} = Mnemonix.Store.start_link({Mnemonix.Map.Store, initial: %{foo: :bar}})
    iex> Mnemonix.get(store, :foo)
    :bar
  """
  @spec start_link(adapter)         :: GenServer.on_start
  @spec start_link({adapter, opts}) :: GenServer.on_start
  def start_link(init) do
    start_link(init, [])
  end

  @doc """
  Starts a new `Mnemonix.Store` using `adapter` with `opts`.

  The returned `GenServer.on_start/0` reference can be used in
  the `Mnemonix` API.

  ## Examples

      iex> {:ok, _store} = Mnemonix.Store.start_link(Mnemonix.Map.Store, name: StoreCache)
      iex> Mnemonix.put(StoreCache, :foo, :bar)
      iex> Mnemonix.get(StoreCache, :foo)
      :bar

      iex> {:ok, _store} = Mnemonix.Store.start_link({Mnemonix.Map.Store, initial: %{foo: :bar}}, name: OtherCache)
      iex> Mnemonix.get(OtherCache, :foo)
      :bar
  """
  def start_link(init, opts)

  @spec start_link({adapter, opts}, GenServer.options) :: GenServer.on_start
  def start_link(adapter, opts) when not is_tuple adapter do
    start_link({adapter, []}, opts)
  end

  @spec start_link(adapter, GenServer.options) :: GenServer.on_start
  def start_link(init, opts) do
    GenServer.start_link(__MODULE__, init, opts)
  end

  use GenServer


  @doc false

  @spec init({adapter, opts}) ::
    {:ok, state} |
    {:ok, state, timeout | :hibernate} |
    :ignore |
    {:stop, reason} when reason: term, timeout: pos_integer

  def init({adapter, opts}) do
    case adapter.init(opts) do
      {:ok, state}          -> {:ok, new(adapter, opts, state)}
      {:ok, state, timeout} -> {:ok, new(adapter, opts, state), timeout}
      other                 -> other
    end
  end

  defp new(adapter, opts, state) do
    %__MODULE__{adapter: adapter, opts: opts, state: state}
  end


  @doc false

  @spec handle_call(request :: term, GenServer.from, t) ::
    {:reply, reply, new_store} |
    {:reply, reply, new_store, timeout | :hibernate} |
    {:noreply, new_store} |
    {:noreply, new_store, timeout | :hibernate} |
    {:stop, reason, reply, new_store} |
    {:stop, reason, new_store}
    when
      reply: term,
      new_store: t,
      reason: term,
      timeout: pos_integer

  ####
  # CORE
  ##

  def handle_call({:delete, key}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.delete(store, key) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  # TODO: expiry
  # def handle_call({:expires, key, time}, _, %__MODULE__{adapter: adapter}) do
  #   case adapter.expires(store, key, time) do
  #     {:ok, store}         -> {:reply, :ok, store}
  #     {:raise, type, args} -> {:reply, {:raise, type, args}, store}
  #   end
  # end

  def handle_call({:fetch, key}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.fetch(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put, key, value}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.put(store, key, value) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  ####
  # MAP FUNCTIONS
  ##

  def handle_call({:fetch!, key}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.fetch!(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get, key}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.get(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get, key, default}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.get(store, key, default) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get_and_update, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.get_and_update(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get_and_update!, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.get_and_update!(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get_lazy, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.get_lazy(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:has_key?, key}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.has_key?(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:pop, key}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.pop(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:pop, key, default}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.pop(store, key, default) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:pop_lazy, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.pop_lazy(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put_new, key, value}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.put_new(store, key, value) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put_new_lazy, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.put_new_lazy(store, key, fun) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:update, key, initial, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.update(store, key, initial, fun) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:update!, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
    case adapter.update!(store, key, fun) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end


  @doc false

  @spec terminate(reason, t) :: reason
    when reason: :normal | :shutdown | {:shutdown, term} | term

  def terminate(reason, store = %__MODULE__{adapter: adapter}) do
    with {:ok, reason} <- adapter.teardown(reason, store) do
      reason
    end
  end

end
