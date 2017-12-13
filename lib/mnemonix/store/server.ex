defmodule Mnemonix.Store.Server do
  @moduledoc """
  Bridges `Mnemonix.Features` with underlying `Mnemonix.Stores`.
  """

  alias Mnemonix.Store
  alias Mnemonix.Features.Bump
  alias Mnemonix.Features.Expiry

  use GenServer

  @type option :: GenServer.option() | {atom, term}
  @type options :: [option]

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to return successfully in the client.
  """
  @type success :: {:ok, Mnemonix.Store.t()}
  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to return given value successfully in the client.
  """
  @type success(return) :: {:ok, Mnemonix.Store.t(), return}

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to emit a warning when returning in the client.
  """
  @type warning :: {:warn, Mnemonix.Store.t(), message :: String.t()}
  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to emit a warning when returning given value in the client.
  """
  @type warning(return) :: {:warn, Mnemonix.Store.t(), message :: String.t(), return}

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to raise an error in the client.
  """
  @type exception :: {:raise, Mnemonix.Store.t(), exception :: module, raise_opts :: Keyword.t()}

  @type instruction :: success | warning | exception
  @type instruction(return) :: success(return) | warning(return) | exception

  @type reply :: Mnemonix.success() | Mnemonix.warning() | Mnemonix.exception()
  @type reply(value) :: Mnemonix.success(value) | Mnemonix.warning(value) | Mnemonix.exception()

  @doc """
  Starts a new store using store `impl`, `store` options, and `server` options.

  `store` will be given to the store on setup. Study the store `impl` for more information.

  `server` options be given to `GenServer.start_link/3`.

  No application configuration checking option merging is performed.

  ## Examples

      iex> {:ok, store} = Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, [])
      iex> Mnemonix.put(store, :foo, :bar)
      iex> Mnemonix.get(store, :foo)
      :bar

      iex> options = [initial: %{foo: :bar}, name: StoreCache]
      iex> {:ok, _store} = Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, options)
      iex> Mnemonix.get(StoreCache, :foo)
      :bar
  """
  @spec start_link(Store.Behaviour.t(), Store.Server.options()) :: GenServer.on_start()
  def start_link(impl, options \\ []) do
    {options, config} = Keyword.split(options, ~w[name timeout debug spawn_opt]a)
    GenServer.start_link(__MODULE__, {impl, config}, options)
  end

  @doc """
  Prepares the underlying store `impl` for usage with supplied `options`.

  Invokes the `c:Mnemonix.Core.Behaviour.setup/1` and `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`
  callbacks.
  """
  @spec init({Store.Behaviour.t(), Store.options()}) ::
          {:ok, Store.t()} | :ignore | {:stop, reason :: term}
  def init({impl, config}) do
    with {:ok, state} <- impl.setup(config),
         store <- Store.new(impl, config, state),
         # {:ok, store} <- impl.setup_expiry(store), #TODO
         {:ok, store} <- impl.setup_initial(store),
         do: {:ok, store}
  end

  @doc """
  Cleans up the underlying store on termination.

  Invokes the `c:Mnemonix.Lifecycle.Behaviour.teardown/2` callback.
  """
  @spec terminate(reason, Store.t()) :: reason
        when reason: :normal | :shutdown | {:shutdown, term} | term
  def terminate(reason, %Store{impl: impl} = store) do
    with {:ok, reason} <- impl.teardown(reason, store) do
      reason
    end
  end

  @doc """
  Delegates Mnemonix.Feature functions to the underlying store behaviours.
  """
  @spec handle_call(request :: term, GenServer.from(), Store.t()) ::
          {:reply, reply, new_store}
          | {:reply, reply, new_store, timeout | :hibernate}
          | {:noreply, new_store}
          | {:noreply, new_store, timeout | :hibernate}
          | {:stop, reason, reply, new_store}
          | {:stop, reason, new_store}
        when reply: reply,
             new_store: Store.t(),
             reason: term,
             timeout: pos_integer

  def handle_call(request, from, store)

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  # Core Map behaviours

  @spec handle_call({:delete, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:delete, key}, _, %Store{impl: impl} = store) do
    case impl.delete(store, serialize_key(store, key)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:fetch, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(:error | {:ok, Mnemonix.value()}), Store.t()}
  def handle_call({:fetch, key}, _, %Store{impl: impl} = store) do
    case impl.fetch(store, serialize_key(store, key)) do
      {:ok, store, :error} ->
        {:reply, {:ok, :error}, store}

      {:ok, store, {:ok, value}} ->
        {:reply, {:ok, {:ok, deserialize_value(store, value)}}, store}

      {:warn, store, message, :error} ->
        {:reply, {:warn, message, :error}, store}

      {:warn, store, message, {:ok, value}} ->
        {:reply, {:warn, message, {:ok, deserialize_value(store, value)}}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:put, Mnemonix.key(), Mnemonix.value()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:put, key, value}, _, %Store{impl: impl} = store) do
    case impl.put(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Map behaviours

  @spec handle_call({:drop, [Mnemonix.key()]}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:drop, keys}, _, %Store{impl: impl} = store) do
    case impl.drop(store, serialize_keys(store, keys)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:fetch!, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:fetch!, key}, _, %Store{impl: impl} = store) do
    case impl.fetch!(store, serialize_key(store, key)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:get, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:get, key}, _, %Store{impl: impl} = store) do
    case impl.get(store, serialize_key(store, key)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call(
          {:get, Mnemonix.key(), default :: Mnemonix.value()},
          GenServer.from(),
          Store.t()
        ) :: {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:get, key, default}, _, %Store{impl: impl} = store) do
    case impl.get(store, serialize_key(store, key), serialize_value(store, default)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:get_and_update, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:get_and_update, key, fun}, _, %Store{impl: impl} = store) do
    case impl.get_and_update(store, serialize_key(store, key), get_and_update_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:get_and_update!, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:get_and_update!, key, fun}, _, %Store{impl: impl} = store) do
    case impl.get_and_update!(store, serialize_key(store, key), get_and_update_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:get_lazy, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:get_lazy, key, fun}, _, %Store{impl: impl} = store) do
    case impl.get_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:has_key?, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(boolean), Store.t()}
  def handle_call({:has_key?, key}, _, %Store{impl: impl} = store) do
    case impl.has_key?(store, serialize_key(store, key)) do
      {:ok, store, bool} ->
        {:reply, {:ok, bool}, store}

      {:warn, store, message, bool} ->
        {:reply, {:warn, message, bool}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:pop, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:pop, key}, _, %Store{impl: impl} = store) do
    case impl.pop(store, serialize_key(store, key)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call(
          {:pop, Mnemonix.key(), default :: Mnemonix.value()},
          GenServer.from(),
          Store.t()
        ) :: {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:pop, key, default}, _, %Store{impl: impl} = store) do
    case impl.pop(store, serialize_key(store, key), serialize_value(store, default)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:pop_lazy, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({:pop_lazy, key, fun}, _, %Store{impl: impl} = store) do
    case impl.pop_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}

      {:warn, store, message, value} ->
        {:reply, {:warn, message, deserialize_value(store, value)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:put_new, Mnemonix.key(), Mnemonix.value()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:put_new, key, value}, _, %Store{impl: impl} = store) do
    case impl.put_new(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:put_new_lazy, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:put_new_lazy, key, fun}, _, %Store{impl: impl} = store) do
    case impl.put_new_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:replace, Mnemonix.key(), Mnemonix.value()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:replace, key, value}, _, %Store{impl: impl} = store) do
    case impl.replace(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:replace!, Mnemonix.key(), Mnemonix.value()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:replace!, key, value}, _, %Store{impl: impl} = store) do
    case impl.replace!(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:split, [Mnemonix.key()]}, GenServer.from(), Store.t()) ::
          {:reply, reply(%{Mnemonix.key() => Mnemonix.value()}), Store.t()}
  def handle_call({:split, keys}, _, %Store{impl: impl} = store) do
    case impl.split(store, serialize_keys(store, keys)) do
      {:ok, store, pairs} when is_list(pairs) ->
        {:reply, {:ok, Enum.into(deserialize_pairs(store, pairs), %{})}, store}

      {:warn, store, message, pairs} when is_list(pairs) ->
        {:reply, {:warn, message, Enum.into(deserialize_pairs(store, pairs), %{})}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:take, [Mnemonix.key()]}, GenServer.from(), Store.t()) ::
          {:reply, reply(%{Mnemonix.key() => Mnemonix.value()}), Store.t()}
  def handle_call({:take, keys}, _, %Store{impl: impl} = store) do
    case impl.take(store, serialize_keys(store, keys)) do
      {:ok, store, pairs} when is_list(pairs) ->
        {:reply, {:ok, Enum.into(deserialize_pairs(store, pairs), %{})}, store}

      {:warn, store, message, pairs} when is_list(pairs) ->
        {:reply, {:warn, message, Enum.into(deserialize_pairs(store, pairs), %{})}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call(
          {:update, Mnemonix.key(), initial :: Mnemonix.value(), fun},
          GenServer.from(),
          Store.t()
        ) :: {:reply, reply, Store.t()}
  def handle_call({:update, key, initial, fun}, _, %Store{impl: impl} = store) do
    case impl.update(
           store,
           serialize_key(store, key),
           serialize_value(store, initial),
           update_value_fun(store, fun)
         ) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:update!, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:update!, key, fun}, _, %Store{impl: impl} = store) do
    case impl.update!(store, serialize_key(store, key), update_value_fun(store, fun)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Access Protocol from Map behaviour

  @spec handle_call({{Access, :fetch}, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(:error | {:ok, Mnemonix.value()}), Store.t()}
  def handle_call({{Access, :fetch}, key}, from, %Store{} = store) do
    handle_call({:fetch, key}, from, store)
  end

  @spec handle_call(
          {{Access, :get}, Mnemonix.key(), default :: Mnemonix.value()},
          GenServer.from(),
          Store.t()
        ) :: {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({{Access, :get}, key, default}, from, %Store{} = store) do
    handle_call({:get, key, default}, from, store)
  end

  @spec handle_call({{Access, :get_and_update}, Mnemonix.key(), fun}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({{Access, :get_and_update}, key, fun}, from, %Store{} = store) do
    handle_call({:get_and_update, key, fun}, from, store)
  end

  @spec handle_call({{Access, :pop}, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply(Mnemonix.value()), Store.t()}
  def handle_call({{Access, :pop}, key}, from, %Store{} = store) do
    handle_call({:pop, key}, from, store)
  end

  ####
  # Mnemonix.Store.Behaviours.Bump
  ##

  # Core Bump behaviours

  @spec handle_call({:bump, Mnemonix.key(), Bump.amount()}, GenServer.from(), Store.t()) ::
          {:reply, reply(Bump.result()), Store.t()}
  def handle_call({:bump, key, amount}, _, %Store{impl: impl} = store) do
    case impl.bump(store, serialize_key(store, key), amount) do
      {:ok, store, result} ->
        {:reply, result, store}

      {:warn, store, message, result} ->
        {:reply, {:warn, message, result}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Bump behaviours

  @spec handle_call({:bump!, Mnemonix.key(), Bump.amount()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:bump!, key, amount}, _, %Store{impl: impl} = store) do
    case impl.bump!(store, serialize_key(store, key), amount) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:increment, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:increment, key}, _, %Store{impl: impl} = store) do
    case impl.increment(store, serialize_key(store, key)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:increment, Mnemonix.key(), Bump.amount()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:increment, key, amount}, _, %Store{impl: impl} = store) do
    case impl.increment(store, serialize_key(store, key), amount) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:decrement, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:decrement, key}, _, %Store{impl: impl} = store) do
    case impl.decrement(store, serialize_key(store, key)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:decrement, Mnemonix.key(), Bump.amount()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:decrement, key, amount}, _, %Store{impl: impl} = store) do
    case impl.decrement(store, serialize_key(store, key), amount) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Expiry
  ##

  # Core Expiry behaviours

  @spec handle_call({:expire, Mnemonix.key(), Expiry.ttl()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:expire, key, ttl}, _, %Store{impl: impl} = store) do
    case impl.expire(store, serialize_key(store, key), ttl) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:persist, Mnemonix.key()}, GenServer.from(), Store.t()) ::
          {:reply, reply, Store.t()}
  def handle_call({:persist, key}, _, %Store{impl: impl} = store) do
    case impl.persist(store, serialize_key(store, key)) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Expiry behaviours

  @spec handle_call(
          {:put_and_expire, Mnemonix.key(), Mnemonix.value(), Expiry.ttl()},
          GenServer.from(),
          Store.t()
        ) :: {:reply, reply, Store.t()}
  def handle_call({:put_and_expire, key, value, ttl}, _, %Store{impl: impl} = store) do
    case impl.put_and_expire(store, serialize_key(store, key), serialize_value(store, value), ttl) do
      {:ok, store} ->
        {:reply, :ok, store}

      {:warn, store, message} ->
        {:reply, {:warn, message}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Enumerable
  ##

  # Core Enumerable behaviours

  @spec handle_call({:enumerable?}, GenServer.from(), Store.t()) ::
          {:reply, reply(boolean), Store.t()}
  def handle_call({:enumerable?}, _, %Store{impl: impl} = store) do
    case impl.enumerable?(store) do
      {:ok, store, enumerability} ->
        {:reply, {:ok, enumerability}, store}

      {:warn, store, message, enumerability} ->
        {:reply, {:warn, message, enumerability}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:to_enumerable}, GenServer.from(), Store.t()) ::
          {:reply, reply([Mnemonix.pair()]), Store.t()}
  def handle_call({:to_enumerable}, _, %Store{impl: impl} = store) do
    case impl.to_enumerable(store) do
      {:ok, store, pairs} when is_list(pairs) ->
        {:reply, {:ok, deserialize_pairs(store, pairs)}, store}

      {:warn, store, message, pairs} when is_list(pairs) ->
        {:reply, {:warn, message, deserialize_pairs(store, pairs)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Enumerable behaviours

  @spec handle_call({:keys}, GenServer.from(), Store.t()) ::
          {:reply, reply([Mnemonix.key()]), Store.t()}
  def handle_call({:keys}, _, %Store{impl: impl} = store) do
    case impl.keys(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, pairs} when is_list(pairs) ->
            {:reply, {:ok, deserialize_keys(store, Enum.map(pairs, &elem(&1, 0)))}, store}

          {:warn, store, message, pairs} when is_list(pairs) ->
            {
              :reply,
              {:warn, message, deserialize_keys(store, Enum.map(pairs, &elem(&1, 0)))},
              store
            }

          {:raise, store, type, args} ->
            reply_with_error(store, type, args)
        end

      {:ok, store, keys} when is_list(keys) ->
        {:reply, {:ok, deserialize_keys(store, keys)}, store}

      {:warn, store, message, keys} when is_list(keys) ->
        {:reply, {:warn, message, deserialize_keys(store, keys)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:to_list}, GenServer.from(), Store.t()) ::
          {:reply, reply([Mnemonix.pair()]), Store.t()}
  def handle_call({:to_list}, _, %Store{impl: impl} = store) do
    case impl.to_list(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, pairs} when is_list(pairs) ->
            {:reply, {:ok, deserialize_pairs(store, pairs)}, store}

          {:warn, store, message, pairs} when is_list(pairs) ->
            {:reply, {:warn, message, deserialize_pairs(store, pairs)}, store}

          {:raise, store, type, args} ->
            reply_with_error(store, type, args)
        end

      {:ok, store, pairs} when is_list(pairs) ->
        {:reply, {:ok, deserialize_pairs(store, pairs)}, store}

      {:warn, store, message, pairs} when is_list(pairs) ->
        {:reply, {:warn, message, deserialize_pairs(store, pairs)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  @spec handle_call({:values}, GenServer.from(), Store.t()) ::
          {:reply, reply([Mnemonix.value()]), Store.t()}
  def handle_call({:values}, _, %Store{impl: impl} = store) do
    case impl.values(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, pairs} when is_list(pairs) ->
            {:reply, {:ok, deserialize_values(store, Enum.map(pairs, &elem(&1, 1)))}, store}

          {:warn, store, message, pairs} when is_list(pairs) ->
            {
              :reply,
              {:warn, message, deserialize_keys(store, Enum.map(pairs, &elem(&1, 1)))},
              store
            }

          {:raise, store, type, args} ->
            reply_with_error(store, type, args)
        end

      {:ok, store, values} when is_list(values) ->
        {:reply, {:ok, deserialize_values(store, values)}, store}

      {:warn, store, message, values} when is_list(values) ->
        {:reply, {:warn, message, deserialize_values(store, values)}, store}

      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # The serialization/deserialization of enumerable_reduce and collectable_into need more thought.

  # Derived Enumerable Protocol from Enumerable behaviour

  # @spec handle_call({Enumerable, :count}, GenServer.from, Store.t)
  #   :: {:reply, reply(non_neg_integer), Store.t}
  # def handle_call({Enumerable, :count}, from, %Store{impl: impl} = store) do
  #   case impl.enumerable_count(store) do
  #     {:ok, store, {:error, ^impl}} ->
  #       reducer = fn _, acc -> {:cont, acc + 1} end
  #       handle_call({{Enumerable, :reduce}, {:cont, 0}, reducer}, from, store)
  #     {:ok, store, count} when is_integer(count) ->
  #       {:reply, {:ok, count}, store}
  #     {:raise, store, type, args} ->
  #       reply_with_error(store, type, args)
  #   end
  # end
  #
  # @spec handle_call({{Enumerable, :member?}, Mnemonix.pair}, GenServer.from, Store.t)
  #   :: {:reply, reply(boolean), Store.t}
  # def handle_call({{Enumerable, :member?}, {_key, _value} = pair}, from, %Store{impl: impl} = store) do
  #   case impl.enumerable_member?(store, serialize_pair(store, pair)) do
  #     {:ok, store, {:error, ^impl}} ->
  #       reducer = fn
  #         entry, _ when entry === pair -> {:halt, true}
  #         _, _                         -> {:cont, false}
  #       end
  #       handle_call({{Enumerable, :reduce}, {:cont, false}, reducer}, from, store)
  #     {:ok, store, membership} when is_boolean(membership) ->
  #       {:reply, {:ok, membership}, store}
  #     {:raise, store, type, args} ->
  #       reply_with_error(store, type, args)
  #   end
  # end
  # @spec handle_call({{Enumerable, :member?}, term}, GenServer.from, Store.t)
  #   :: {:reply, reply(false), Store.t}
  # def handle_call({{Enumerable, :member?}, _not_pair}, _, %Store{} = store) do
  #   {:reply, {:ok, false}, store}
  # end
  #
  # @spec handle_call({{Enumerable, :reduce}, acc :: term, reducer :: fun}, GenServer.from, Store.t)
  #   :: {:reply, reply(Enumerable.result), Store.t}
  # def handle_call({{Enumerable, :reduce}, acc, reducer}, _, %Store{impl: impl} = store) do
  #   case impl.enumerable_reduce(store, acc, reducer_fun(store, reducer)) do
  #     {:ok, store, {:error, ^impl}} ->
  #       case impl.to_enumerable(store) do
  #         {:ok, store, enumerable} ->
  #           {:reply, {:ok, Enumerable.reduce(enumerable, acc, reducer_fun(store, reducer))}, store}
  #         {:raise, store, type, args} ->
  #           reply_with_error(store, type, args)
  #       end
  #     {:ok, store, result} ->
  #       {:reply, {:ok, result}, store}
  #     {:raise, store, type, args} ->
  #       reply_with_error(store, type, args)
  #   end
  # end

  # Derived Collectable Protocol from Enumerable behaviour

  # @spec handle_call({{Collectable, :into}, Enumerable.t}, GenServer.from, Store.t)
  #   :: {:reply, reply({term, (term, command -> Collectable.t | term)}), Store.t}
  # def handle_call({{Collectable, :into}, enumerable}, _, %Store{impl: impl} = store) do
  #   case impl.collectable_into(store, enumerable) do
  #     {:ok, store, {:error, ^impl}} ->
  #       case impl.to_enumerable(store) do
  #         {:ok, store, enumerable} ->
  #           {accumulator, collector} = Collectable.into(enumerable)
  #           {:reply, {:ok, {accumulator, collector_fun(store, collector)}}, store}
  #         {:raise, store, type, args} ->
  #           reply_with_error(store, type, args)
  #       end
  #     {:ok, store, {accumulator, collector}} ->
  #       {:reply, {:ok, {accumulator, collector_fun(store, collector)}}, store}
  #     {:raise, store, type, args} ->
  #       reply_with_error(store, type, args)
  #   end
  # end

  # Monads for keeping serialization transparent while still applying user-provided functions

  defp produce_value_fun(store, fun) do
    fn ->
      serialize_value(store, fun.())
    end
  end

  defp update_value_fun(store, fun) do
    fn value ->
      serialize_value(store, fun.(deserialize_value(store, value)))
    end
  end

  defp get_and_update_fun(store, fun) do
    fn value ->
      case fun.(deserialize_value(store, value)) do
        {return, transformed} ->
          {serialize_value(store, return), serialize_value(store, transformed)}

        :pop ->
          :pop
      end
    end
  end

  # defp reducer_fun(store, fun) do
  #   fn {key, value}, acc ->
  #     fun.(deserialize_pair(store, {key, value}), acc)
  #   end
  #   # fn
  #   #   list,    {:halt, acc}, fun), -> {:halted, acc}
  #   #   list,    {:suspend, acc}, fun), -> {:suspended, acc, &reduce(list, &1, fun)}
  #   #   [],      {:cont, acc}, fun), -> {:done, acc}
  #   #   [h | t], {:cont, acc}, fun), -> reduce(t, fun.(h, acc), fun)
  #   # end
  # end
  #
  # defp collector_fun(store, fun) do
  #   fn
  #     enum, {:cont, pair} -> fun.(enum, {:cont, deserialize_pair(store, pair)})
  #     enum, :done -> fun.(enum, :done)
  #     enum, :halt -> fun.(enum, :halt)
  #   end
  # end

  defp serialize_key(%Store{impl: impl} = store, key), do: impl.serialize_key(store, key)
  defp deserialize_key(%Store{impl: impl} = store, key), do: impl.deserialize_key(store, key)
  defp serialize_value(%Store{impl: impl} = store, value), do: impl.serialize_value(store, value)

  defp deserialize_value(%Store{impl: impl} = store, value),
    do: impl.deserialize_value(store, value)

  defp serialize_keys(%Store{} = store, keys), do: Enum.map(keys, &serialize_key(store, &1))
  defp deserialize_keys(%Store{} = store, keys), do: Enum.map(keys, &deserialize_key(store, &1))

  # defp serialize_values(%Store{} = store, values),
  #   do: Enum.map(values, &(serialize_value(store, &1)))
  defp deserialize_values(%Store{} = store, values),
    do: Enum.map(values, &deserialize_value(store, &1))

  # defp serialize_pair(%Store{} = store, {key, value}),
  #   do: {serialize_key(store, key), serialize_value(store, value)}
  defp deserialize_pair(%Store{} = store, {key, value}),
    do: {deserialize_key(store, key), deserialize_value(store, value)}

  # defp serialize_pairs(%Store{} = store, pairs),
  #   do: Enum.map(pairs, &(serialize_pair(store, &1)))
  defp deserialize_pairs(%Store{} = store, pairs),
    do: Enum.map(pairs, &deserialize_pair(store, &1))

  defp reply_with_error(store, type, args) do
    {:reply, {:raise, type, deserialize_error_args(store, args)}, store}
  end

  # Deserialize keys to be displayed in error messages

  defp deserialize_error_args(store, args) when is_list(args) do
    case Keyword.fetch(args, :key) do
      :error -> args
      {:ok, key} -> Keyword.put(args, :key, deserialize_key(store, key))
    end
  end

  defp deserialize_error_args(_store, args), do: args
end
