defmodule Mnemonix.Store do
  @moduledoc """
  Normalizes access to different key-value stores behind a `GenServer`.

  Once a store [has been started](#start_link/1), you can use `Mnemonix`
  methods to manipulate it:

      iex> Mnemonix.Store.start_link(Mnemonix.Map.Store, name: Store)
      iex> Mnemonix.put(Store, :foo, "bar")
      iex> Mnemonix.fetch(Store, :foo)
      {:ok, "bar"}
      iex> Mnemonix.delete(Store, :foo)
      iex> Mnemonix.fetch(Store, :foo)
      :error
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

  The returned `t:GenServer.server/0` reference can be used in
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

  The returned `t:GenServer.server/0` reference can be used in
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

  use Mnemonix.Store.Lifecycle.Callbacks

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

  use Mnemonix.Store.Map.Callbacks
  use Mnemonix.Store.Bump.Callbacks

end
