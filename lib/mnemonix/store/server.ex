defmodule Mnemonix.Store.Server do
  @moduledoc """
  Bridges Mnemonix.Features with Mnemonix.Store.Behaviour implementations.
  """

  use Mnemonix.Store.Types, [:store, :impl, :opts]

  @doc """
  Starts a new `Mnemonix.Store.Server` using `impl`.

  If you wish to pass options to `GenServer.start_link/3`, use `start_link/2`.

  The returned `t:GenServer.server/0` reference can be used in
  the `Mnemonix` API.

  ## Examples

    iex> {:ok, store} = Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map)
    iex> Mnemonix.put(store, :foo, :bar)
    iex> Mnemonix.get(store, :foo)
    :bar

    iex> {:ok, store} = Mnemonix.Store.Server.start_link({Mnemonix.Stores.Map, initial: %{foo: :bar}})
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

      iex> {:ok, _store} = Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, name: StoreCache)
      iex> Mnemonix.put(StoreCache, :foo, :bar)
      iex> Mnemonix.get(StoreCache, :foo)
      :bar

      iex> {:ok, _store} = Mnemonix.Store.Server.start_link({Mnemonix.Stores.Map, initial: %{foo: :bar}}, name: OtherCache)
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

  Invokes the `c:Mnemonix.Core.Behaviour.setup/1` and `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`
  callbacks.
  """
  @spec init({impl, opts}) :: {:ok, store} | :ignore | {:stop, reason :: term}
  def init({impl, opts}) do
    with {:ok, state} <- impl.setup(opts),
         store        <- Mnemonix.Store.new(impl, opts, state),
         {:ok, store} <- impl.setup_expiry(store),
    do: {:ok, store}
  end


  @doc """
  Cleans up the underlying store on termination.

  Invokes the `c:Mnemonix.Lifecycle.Behaviour.teardown/2` callback.
  """
  @spec terminate(reason, store) :: reason
    when reason: :normal | :shutdown | {:shutdown, term} | term
  def terminate(reason, store = %Mnemonix.Store{impl: impl}) do
    with {:ok, reason} <- impl.teardown(reason, store) do
      reason
    end
  end

  @doc """
  Delegates Mnemonix.API functions to the underlying store behaviours.
  """
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

  ####
  # Mnemonix.Store.Behaviours.Core
  ##

  def handle_call({:delete, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.delete(store, key) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:fetch, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.fetch(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put(store, key, value) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  def handle_call({:fetch!, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.fetch!(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get, key, default}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get(store, key, default) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get_and_update, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get_and_update(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get_and_update!, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get_and_update!(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:get_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get_lazy(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:has_key?, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.has_key?(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:pop, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.pop(store, key) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:pop, key, default}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.pop(store, key, default) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:pop_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.pop_lazy(store, key, fun) do
      {:ok, store, value}  -> {:reply, {:ok, value}, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put_new, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put_new(store, key, value) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put_new_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put_new_lazy(store, key, fun) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:update, key, initial, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.update(store, key, initial, fun) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:update!, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.update!(store, key, fun) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Expiry
  ##

  def handle_call({:expire, key, ttl}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.expire(store, key, ttl) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:persist, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.persist(store, key) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:put_and_expire, key, value, ttl}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put_and_expire(store, key, value, ttl) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Bump
  ##

  def handle_call({:bump, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.bump(store, key, amount) do
      {:ok, store, value}  -> {:reply, value, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:bump!, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.bump!(store, key, amount) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:increment, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.increment(store, key) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:increment, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.increment(store, key, amount) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:decrement, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.decrement(store, key) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

  def handle_call({:decrement, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.decrement(store, key, amount) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> {:reply, {:raise, type, args}, store}
    end
  end

end
