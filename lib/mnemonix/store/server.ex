defmodule Mnemonix.Store.Server do

  use Mnemonix.Store.Types, [:store, :impl, :opts]

  @doc """
  Starts a new `Mnemonix.Store.Server` using `impl`.

  If you wish to pass options to `GenServer.start_link/3`, use `start_link/2`.

  The returned `t:GenServer.server/0` reference can be used in
  the `Mnemonix` API.

  ## Examples

    iex> {:ok, store} = Mnemonix.Store.Server.start_link(Mnemonix.Map.Store)
    iex> Mnemonix.put(store, :foo, :bar)
    iex> Mnemonix.get(store, :foo)
    :bar

    iex> {:ok, store} = Mnemonix.Store.Server.start_link({Mnemonix.Map.Store, initial: %{foo: :bar}})
    iex> Mnemonix.get(store, :foo)
    :bar
  """
  @spec start_link(impl)         :: GenServer.on_start
  @spec start_link({impl, opts}) :: GenServer.on_start
  def start_link(init) do
    start_link(init, [])
  end

  @doc """
  Starts a new `Mnemonix.Store.Server` using `impl` with `opts`.

  The returned `t:GenServer.server/0` reference can be used in
  the `Mnemonix` API.

  ## Examples

      iex> {:ok, _store} = Mnemonix.Store.Server.start_link(Mnemonix.Map.Store, name: StoreCache)
      iex> Mnemonix.put(StoreCache, :foo, :bar)
      iex> Mnemonix.get(StoreCache, :foo)
      :bar

      iex> {:ok, _store} = Mnemonix.Store.Server.start_link({Mnemonix.Map.Store, initial: %{foo: :bar}}, name: OtherCache)
      iex> Mnemonix.get(OtherCache, :foo)
      :bar
  """
  def start_link(init, opts)

  @spec start_link({impl, opts}, GenServer.options) :: GenServer.on_start
  def start_link(impl, opts) when not is_tuple impl do
    start_link({impl, []}, opts)
  end

  @spec start_link(impl, GenServer.options) :: GenServer.on_start
  def start_link(init, opts) do
    GenServer.start_link(__MODULE__, init, opts)
  end

  use GenServer

  @doc """
  Prepares the underlying store type for usage with supplied options.

  Invokes the `setup/1` callback and initialization callbacks required by store utilities:

  - `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`
  """
  @spec init({impl, opts}) :: {:ok, store} | :ignore | {:stop, reason :: term}
  def init({impl, opts}) do
    with {:ok, state} <- impl.setup(opts),
         store        <- Mnemonix.Store.new(impl, opts, state),
         {:ok, store} <- impl.setup_expiry(store),
    do: {:ok, store}
  end

  use Mnemonix.Store.Lifecycle.Handlers

  @doc false
  @spec handle_call(request :: term, GenServer.from, store) ::
    {:reply, reply, new_store} |
    {:reply, reply, new_store, timeout | :hibernate} |
    {:noreply, new_store} |
    {:noreply, new_store, timeout | :hibernate} |
    {:stop, reason, reply, new_store} |
    {:stop, reason, new_store}
    when
      reply: term,
      new_store: store,
      reason: term,
      timeout: pos_integer

  use Mnemonix.Store.Core.Handlers
  use Mnemonix.Store.Map.Handlers
  use Mnemonix.Store.Expiry.Handlers
  use Mnemonix.Store.Bump.Handlers

end
