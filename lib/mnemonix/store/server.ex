defmodule Mnemonix.Store.Server do
  @moduledoc """
  Bridges `Mnemonix.Features` with underlying `Mnemonix.Stores`.
  """ && false

  use GenServer

  @type reply :: :ok | {:ok, term} | Mnemonix.Store.Behaviour.exception

  @doc """
  Starts a new store using store `impl`, `store` options, and `server` options.

  `store` will be given to the store on setup. Study the store `impl` for more information.

  `server` options be given to `GenServer.start_link/3`.

  No application configuration checking option merging is performed.

  ## Examples

      iex> {:ok, store} = Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, [], [])
      iex> Mnemonix.put(store, :foo, :bar)
      iex> Mnemonix.get(store, :foo)
      :bar

      iex> store = [initial: %{foo: :bar}]
      iex> server = [name: StoreCache]
      iex> {:ok, _store} = Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, store, server)
      iex> Mnemonix.get(StoreCache, :foo)
      :bar
  """
  @spec start_link(Mnemonix.Store.Behaviour.t, Mnemonix.Store.options, GenServer.opts) :: GenServer.on_start
  def start_link(impl, store, server) do
    GenServer.start_link(__MODULE__, {impl, store}, server)
  end

  @doc """
  Prepares the underlying store `impl` for usage with supplied `options`.

  Invokes the `c:Mnemonix.Core.Behaviour.setup/1` and `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`
  callbacks.
  """
  @spec init({Mnemonix.Store.Behaviour.t, Mnemonix.Store.options})
    :: {:ok, Mnemonix.Store.t} | :ignore | {:stop, reason :: term}
  def init({impl, options}) do
    with {:ok, state} <- impl.setup(options),
         store        <- Mnemonix.Store.new(impl, options, state),
         {:ok, store} <- impl.setup_expiry(store),
         {:ok, store} <- impl.setup_initial(store),
    do: {:ok, store}
  end


  @doc """
  Cleans up the underlying store on termination.

  Invokes the `c:Mnemonix.Lifecycle.Behaviour.teardown/2` callback.
  """
  @spec terminate(reason, Mnemonix.Store.t) :: reason
    when reason: :normal | :shutdown | {:shutdown, term} | term
  def terminate(reason, store = %Mnemonix.Store{impl: impl}) do
    with {:ok, reason} <- impl.teardown(reason, store) do
      reason
    end
  end

  @doc """
  Delegates Mnemonix.Feature functions to the underlying store behaviours.
  """
  @spec handle_call(request :: term, GenServer.from, Mnemonix.Store.t) ::
    {:reply, reply, new_store} |
    {:reply, reply, new_store, timeout | :hibernate} |
    {:noreply, new_store} |
    {:noreply, new_store, timeout | :hibernate} |
    {:stop, reason, reply, new_store} |
    {:stop, reason, new_store}
    when
      reply: reply,
      new_store: Mnemonix.Store.t,
      reason: term,
      timeout: pos_integer

  def handle_call(request, from, store)

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  # Core Map behaviours

  def handle_call({:delete, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.delete(store, serialize_key(store, key)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:fetch, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.fetch(store, serialize_key(store, key)) do
      {:ok, store, :error}        -> {:reply, {:ok, :error}, store}
      {:ok, store, {:ok, value}}  -> {:reply, {:ok, {:ok, deserialize_value(store, value)}}, store}
      {:raise, type, args}        -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:put, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  # Derived Map behaviours

  def handle_call({:drop, keys}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.drop(store, keys) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:fetch!, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.fetch!(store, serialize_key(store, key)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:get, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get(store, serialize_key(store, key)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:get, key, default}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get(store, serialize_key(store, key), serialize_value(store, default)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:get_and_update, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get_and_update(store, serialize_key(store, key), get_and_update_fun(store, fun)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:get_and_update!, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get_and_update!(store, serialize_key(store, key), get_and_update_fun(store, fun)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:get_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.get_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:has_key?, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.has_key?(store, serialize_key(store, key)) do
      {:ok, store, bool}  -> {:reply, {:ok, bool}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:pop, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.pop(store, serialize_key(store, key)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:pop, key, default}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.pop(store, serialize_key(store, key), serialize_value(store, default)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:pop_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.pop_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, value}  -> {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:put_new, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put_new(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:put_new_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put_new_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:replace, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.replace(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:replace!, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.replace!(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:take, keys}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.take(store, keys) do
      {:ok, store, result} -> {:reply, {:ok, result}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:split, keys}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.split(store, keys) do
      {:ok, store, result} -> {:reply, {:ok, result}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:update, key, initial, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.update(store, serialize_key(store, key), serialize_value(store, initial), update_value_fun(store, fun)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:update!, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.update!(store, serialize_key(store, key), update_value_fun(store, fun)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  # Derived Access Protocol from Map behaviour

  def handle_call({{Access, :fetch}, key}, from, store = %Mnemonix.Store{}) do
    handle_call({:fetch, key}, from, store)
  end

  def handle_call({{Access, :get}, key, default}, from, store = %Mnemonix.Store{}) do
    handle_call({:get, key, default}, from, store)
  end

  def handle_call({{Access, :get_and_update}, key, fun}, from, store = %Mnemonix.Store{}) do
    handle_call({:get_and_update, key, fun}, from, store)
  end

  def handle_call({{Access, :pop}, key}, from, store = %Mnemonix.Store{}) do
    handle_call({:pop, key}, from, store)
  end

  ####
  # Mnemonix.Store.Behaviours.Bump
  ##

  # Core Bump behaviours

  def handle_call({:bump, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.bump(store, serialize_key(store, key), amount) do
      {:ok, store, bump_op}  -> {:reply, bump_op, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  # Derived Bump behaviours

  def handle_call({:bump!, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.bump!(store, serialize_key(store, key), amount) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:increment, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.increment(store, serialize_key(store, key)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:increment, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.increment(store, serialize_key(store, key), amount) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:decrement, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.decrement(store, serialize_key(store, key)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:decrement, key, amount}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.decrement(store, serialize_key(store, key), amount) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Expiry
  ##

  # Core Expiry behaviours

  def handle_call({:expire, key, ttl}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.expire(store, serialize_key(store, key), ttl) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({:persist, key}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.persist(store, serialize_key(store, key)) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  # Derived Expiry behaviours

  def handle_call({:put_and_expire, key, value, ttl}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.put_and_expire(store, serialize_key(store, key), serialize_value(store, value), ttl) do
      {:ok, store}         -> {:reply, :ok, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Enumerable
  ##

  # Core Enumerable behaviours

  def handle_call(:enumerable?, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.enumerable?(store) do
      {:ok, store, enumerable} -> {:reply, {:ok, enumerable}, store}
      {:raise, type, args}     -> reply_with_error(store, type, args)
    end
  end

  def handle_call(:to_enumerable, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.to_enumerable(store) do
      {:ok, store, enumerable} -> {:reply, {:ok, enumerable}, store}
      {:raise, type, args}     -> reply_with_error(store, type, args)
    end
  end

  # Derived Enumerable behaviours

  def handle_call(:keys, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.keys(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} -> {:reply, {:ok, Enum.map(enumerable, &(elem &1, 0))}, store}
          {:raise, type, args} -> reply_with_error(store, type, args)
        end
      {:ok, store, keys} when is_list(keys) ->
        {:reply, {:ok, keys}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call(:to_list, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.to_list(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} -> {:reply, {:ok, Enum.into(enumerable, [])}, store}
          {:raise, type, args}     -> reply_with_error(store, type, args)
        end
      {:ok, store, list} when is_list(list) ->
        {:reply, {:ok, list}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call(:values, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.values(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} -> {:reply, {:ok, Enum.map(enumerable, &(elem &1, 1))}, store}
          {:raise, type, args} -> reply_with_error(store, type, args)
        end
      {:ok, store, values} when is_list(values) ->
        {:reply, {:ok, values}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  # Derived Enumerable Protocol from Enumerable behaviour

  def handle_call({Enumerable, :count}, from, store = %Mnemonix.Store{impl: impl}) do
    case impl.enumerable_count(store) do
      {:ok, store, {:error, ^impl}} ->
        reducer = fn _, acc -> {:cont, acc + 1} end
        handle_call({{Enumerable, :reduce}, {:cont, 0}, reducer}, from, store)
      {:ok, store, count} when is_integer(count) ->
        {:reply, {:ok, count}, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({{Enumerable, :member?}, {_key, _value} = element}, from, store = %Mnemonix.Store{impl: impl}) do
    case impl.enumerable_member?(store, element) do
      {:ok, store, {:error, ^impl}} ->
        reducer = fn
          e, _ when e === element -> {:halt, true}
          _, _                    -> {:cont, false}
        end
        handle_call({{Enumerable, :reduce}, {:cont, false}, reducer}, from, store)
      {:ok, store, member} when is_boolean(member) ->
        {:reply, :ok, member, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  def handle_call({{Enumerable, :reduce}, acc, reducer}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.enumerable_reduce(store, acc, reducer) do
      {:ok, store, {:error, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} -> {:ok, store, Enumerable.reduce(enumerable, acc, reducer)}
          {:raise, type, args} -> reply_with_error(store, type, args)
        end
      {:ok, store, result} -> {:reply, :ok, result, store}
      {:raise, type, args} -> reply_with_error(store, type, args)
    end
  end

  # Derived Collectable Protocol from Enumerable behaviour

  def handle_call({{Collectable, :into}, shape}, _, store = %Mnemonix.Store{impl: impl}) do
    case impl.to_enumerable(store) do
      {:ok, store, enumerable} -> {:reply, {:ok, Enum.into(enumerable, shape)}, store}
      {:raise, type, args}     -> reply_with_error(store, type, args)
    end
  end

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

  def serialize_key(store = %Mnemonix.Store{impl: impl}, key) do
    impl.serialize_key(store, key)
  end
  def serialize_value(store = %Mnemonix.Store{impl: impl}, value) do
    impl.serialize_value(store, value)
  end
  def deserialize_key(store = %Mnemonix.Store{impl: impl}, key) do
    impl.deserialize_key(store, key)
  end
  def deserialize_value(store = %Mnemonix.Store{impl: impl}, value) do
    impl.deserialize_value(store, value)
  end

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
