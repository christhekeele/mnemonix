defmodule Mnemonix.Store.Server do
  @moduledoc """
  Bridges `Mnemonix.Features` with underlying `Mnemonix.Stores`.
  """

  alias Mnemonix.Store

  use GenServer

  @type option :: GenServer.option | {atom, term}
  @type options :: [option]

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to return given value successfully in the client.
  """
  @type success(value) :: {:ok, Mnemonix.Store.t, value}

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to emit a warning when returning given value in the client.
  """
  @type warning(value) :: {:warn, Mnemonix.Store.t, message :: String.t, value}

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to raise an error in the client.
  """
  @type exception :: {:raise, Mnemonix.Store.t, exception :: module, raise_opts :: Keyword.t}

  @type instruction(return) :: success(return) | warning(return) | exception

  @type reply(value) :: Mnemonix.success(value) | Mnemonix.warning(value) | Mnemonix.exception

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
  @spec start_link(Store.Behaviour.t, Store.Server.options) :: GenServer.on_start
  def start_link(impl, options \\ []) do
    {options, config} = Keyword.split(options, ~w[name timeout debug spawn_opt]a)
    GenServer.start_link(__MODULE__, {impl, config}, options)
  end

  @doc """
  Prepares the underlying store `impl` for usage with supplied `options`.

  Invokes the `c:Mnemonix.Core.Behaviour.setup/1` and `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`
  callbacks.
  """
  @spec init({Store.Behaviour.t, Store.options})
    :: {:ok, Store.t} | :ignore | {:stop, reason :: term}
  def init({impl, config}) do
    with {:ok, state} <- impl.setup(config),
         store        <- Store.new(impl, config, state),
         # {:ok, store} <- impl.setup_expiry(store), #TODO
         {:ok, store} <- impl.setup_initial(store),
    do: {:ok, store}
  end


  @doc """
  Cleans up the underlying store on termination.

  Invokes the `c:Mnemonix.Lifecycle.Behaviour.teardown/2` callback.
  """
  @spec terminate(reason, Store.t) :: reason
    when reason: :normal | :shutdown | {:shutdown, term} | term
  def terminate(reason, store = %Store{impl: impl}) do
    with {:ok, reason} <- impl.teardown(reason, store) do
      reason
    end
  end

  @doc """
  Delegates Mnemonix.Feature functions to the underlying store behaviours.
  """
  @spec handle_call(request :: term, GenServer.from, Store.t) ::
    {:reply, reply, new_store} |
    {:reply, reply, new_store, timeout | :hibernate} |
    {:noreply, new_store} |
    {:noreply, new_store, timeout | :hibernate} |
    {:stop, reason, reply, new_store} |
    {:stop, reason, new_store}
    when
      reply: reply,
      new_store: Store.t,
      reason: term,
      timeout: pos_integer

  def handle_call(request, from, store)

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

  # Core Map behaviours

  def handle_call({:delete, key}, _, store = %Store{impl: impl}) do
    case impl.delete(store, serialize_key(store, key)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:fetch, key}, _, store = %Store{impl: impl}) do
    case impl.fetch(store, serialize_key(store, key)) do
      {:ok, store, :error} ->
        {:reply, {:ok, :error}, store}
      {:ok, store, {:ok, value}} ->
        {:reply, {:ok, {:ok, deserialize_value(store, value)}}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:put, key, value}, _, store = %Store{impl: impl}) do
    case impl.put(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Map behaviours

  def handle_call({:drop, keys}, _, store = %Store{impl: impl}) do
    case impl.drop(store, serialize_keys(store, keys)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:fetch!, key}, _, store = %Store{impl: impl}) do
    case impl.fetch!(store, serialize_key(store, key)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:get, key}, _, store = %Store{impl: impl}) do
    case impl.get(store, serialize_key(store, key)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:get, key, default}, _, store = %Store{impl: impl}) do
    case impl.get(store, serialize_key(store, key), serialize_value(store, default)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:get_and_update, key, fun}, _, store = %Store{impl: impl}) do
    case impl.get_and_update(store, serialize_key(store, key), get_and_update_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:get_and_update!, key, fun}, _, store = %Store{impl: impl}) do
    case impl.get_and_update!(store, serialize_key(store, key), get_and_update_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:get_lazy, key, fun}, _, store = %Store{impl: impl}) do
    case impl.get_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:has_key?, key}, _, store = %Store{impl: impl}) do
    case impl.has_key?(store, serialize_key(store, key)) do
      {:ok, store, bool} ->
        {:reply, {:ok, bool}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:pop, key}, _, store = %Store{impl: impl}) do
    case impl.pop(store, serialize_key(store, key)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:pop, key, default}, _, store = %Store{impl: impl}) do
    case impl.pop(store, serialize_key(store, key), serialize_value(store, default)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:pop_lazy, key, fun}, _, store = %Store{impl: impl}) do
    case impl.pop_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, value} ->
        {:reply, {:ok, deserialize_value(store, value)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:put_new, key, value}, _, store = %Store{impl: impl}) do
    case impl.put_new(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:put_new_lazy, key, fun}, _, store = %Store{impl: impl}) do
    case impl.put_new_lazy(store, serialize_key(store, key), produce_value_fun(store, fun)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:replace, key, value}, _, store = %Store{impl: impl}) do
    case impl.replace(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:replace!, key, value}, _, store = %Store{impl: impl}) do
    case impl.replace!(store, serialize_key(store, key), serialize_value(store, value)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:take, keys}, _, store = %Store{impl: impl}) do
    case impl.take(store, serialize_keys(store, keys)) do
      {:ok, store, result} ->
        {:reply, {:ok, result}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:split, keys}, _, store = %Store{impl: impl}) do
    case impl.split(store, serialize_keys(store, keys)) do
      {:ok, store, result} ->
        {:reply, {:ok, result}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:update, key, initial, fun}, _, store = %Store{impl: impl}) do
    case impl.update(store, serialize_key(store, key), serialize_value(store, initial), update_value_fun(store, fun)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:update!, key, fun}, _, store = %Store{impl: impl}) do
    case impl.update!(store, serialize_key(store, key), update_value_fun(store, fun)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Access Protocol from Map behaviour

  def handle_call({{Access, :fetch}, key}, from, store = %Store{}) do
    handle_call({:fetch, key}, from, store)
  end

  def handle_call({{Access, :get}, key, default}, from, store = %Store{}) do
    handle_call({:get, key, default}, from, store)
  end

  def handle_call({{Access, :get_and_update}, key, fun}, from, store = %Store{}) do
    handle_call({:get_and_update, key, fun}, from, store)
  end

  def handle_call({{Access, :pop}, key}, from, store = %Store{}) do
    handle_call({:pop, key}, from, store)
  end

  ####
  # Mnemonix.Store.Behaviours.Bump
  ##

  # Core Bump behaviours

  def handle_call({:bump, key, amount}, _, store = %Store{impl: impl}) do
    case impl.bump(store, serialize_key(store, key), amount) do
      {:ok, store, operation} ->
        {:reply, operation, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Bump behaviours

  def handle_call({:bump!, key, amount}, _, store = %Store{impl: impl}) do
    case impl.bump!(store, serialize_key(store, key), amount) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:increment, key}, _, store = %Store{impl: impl}) do
    case impl.increment(store, serialize_key(store, key)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:increment, key, amount}, _, store = %Store{impl: impl}) do
    case impl.increment(store, serialize_key(store, key), amount) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:decrement, key}, _, store = %Store{impl: impl}) do
    case impl.decrement(store, serialize_key(store, key)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:decrement, key, amount}, _, store = %Store{impl: impl}) do
    case impl.decrement(store, serialize_key(store, key), amount) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Expiry
  ##

  # Core Expiry behaviours

  def handle_call({:expire, key, ttl}, _, store = %Store{impl: impl}) do
    case impl.expire(store, serialize_key(store, key), ttl) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call({:persist, key}, _, store = %Store{impl: impl}) do
    case impl.persist(store, serialize_key(store, key)) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Expiry behaviours

  def handle_call({:put_and_expire, key, value, ttl}, _, store = %Store{impl: impl}) do
    case impl.put_and_expire(store, serialize_key(store, key), serialize_value(store, value), ttl) do
      {:ok, store, :ok} ->
        {:reply, :ok, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  ####
  # Mnemonix.Store.Behaviours.Enumerable
  ##

  # Core Enumerable behaviours

  def handle_call(:enumerable?, _, store = %Store{impl: impl}) do
    case impl.enumerable?(store) do
      {:ok, store, enumerability} ->
        {:reply, {:ok, enumerability}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call(:to_enumerable, _, store = %Store{impl: impl}) do
    case impl.to_enumerable(store) do
      {:ok, store, enumerable} ->
        {:reply, {:ok, enumerable}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # Derived Enumerable behaviours

  def handle_call(:keys, _, store = %Store{impl: impl}) do
    case impl.keys(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} ->
            {:reply, {:ok, deserialize_keys(store, Enum.map(enumerable, &(elem &1, 0)))}, store}
          {:raise, store, type, args} ->
            reply_with_error(store, type, args)
        end
      {:ok, store, keys} when is_list(keys) ->
        {:reply, {:ok, deserialize_keys(store, keys)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call(:to_list, _, store = %Store{impl: impl}) do
    case impl.to_list(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} ->
            {:reply, {:ok, deserialize_pairs(store, Enum.into(enumerable, []))}, store}
          {:raise, store, type, args} ->
            reply_with_error(store, type, args)
        end
      {:ok, store, list} when is_list(list) ->
        {:reply, {:ok, deserialize_pairs(store, list)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  def handle_call(:values, _, store = %Store{impl: impl}) do
    case impl.values(store) do
      {:ok, store, {:default, ^impl}} ->
        case impl.to_enumerable(store) do
          {:ok, store, enumerable} ->
            {:reply, {:ok, deserialize_values(store, Enum.map(enumerable, &(elem &1, 1)))}, store}
          {:raise, store, type, args} ->
            reply_with_error(store, type, args)
        end
      {:ok, store, values} when is_list(values) ->
        {:reply, {:ok, deserialize_values(store, values)}, store}
      {:raise, store, type, args} ->
        reply_with_error(store, type, args)
    end
  end

  # The serialization/deserialization of enumerable_reduce and collectable_into need more thought.

  # Derived Enumerable Protocol from Enumerable behaviour

  # def handle_call({Enumerable, :count}, from, store = %Store{impl: impl}) do
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
  # def handle_call({{Enumerable, :member?}, {_key, _value} = pair}, from, store = %Store{impl: impl}) do
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
  # def handle_call({{Enumerable, :member?}, _not_pair}, _, store = %Store{}) do
  #   {:reply, {:ok, false}, store}
  # end
  #
  # def handle_call({{Enumerable, :reduce}, acc, reducer}, _, store = %Store{impl: impl}) do
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

  # def handle_call({{Collectable, :into}, enumerable}, _, store = %Store{impl: impl}) do
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

  defp serialize_key(store = %Store{impl: impl}, key),             do: impl.serialize_key(store, key)
  defp deserialize_key(store = %Store{impl: impl}, key),           do: impl.deserialize_key(store, key)
  defp serialize_value(store = %Store{impl: impl}, value),         do: impl.serialize_value(store, value)
  defp deserialize_value(store = %Store{impl: impl}, value),       do: impl.deserialize_value(store, value)

  defp serialize_keys(store = %Store{}, keys),       do: Enum.map(keys, &(serialize_key(store, &1)))
  defp deserialize_keys(store = %Store{}, keys),     do: Enum.map(keys, &(deserialize_key(store, &1)))
  # defp serialize_values(store = %Store{}, values),   do: Enum.map(values, &(serialize_value(store, &1)))
  defp deserialize_values(store = %Store{}, values), do: Enum.map(values, &(deserialize_value(store, &1)))

  # defp serialize_pair(store = %Store{}, {key, value}),   do: {serialize_key(store, key), serialize_value(store, value)}
  defp deserialize_pair(store = %Store{}, {key, value}), do: {deserialize_key(store, key), deserialize_value(store, value)}
  # defp serialize_pairs(store = %Store{}, pairs),     do: Enum.map(pairs, &(serialize_pair(store, &1)))
  defp deserialize_pairs(store = %Store{}, pairs),   do: Enum.map(pairs, &(deserialize_pair(store, &1)))

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
