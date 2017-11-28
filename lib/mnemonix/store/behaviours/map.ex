defmodule Mnemonix.Store.Behaviours.Map do
  @moduledoc false

  alias Mnemonix.Store

  use Mnemonix.Behaviour

####
# MANDATORY
##

  @callback delete(Store.t, Mnemonix.key)
    :: Store.Server.instruction

  @callback fetch(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)

  @callback put(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction

####
# DERIVABLE
##

  @callback drop(Store.t, [Mnemonix.key])
    :: Store.Server.instruction
  @doc false
  @spec drop(Store.t, [Mnemonix.key])
    :: Store.Server.instruction
  def drop(store, keys) do
    try do
      Enum.reduce(keys, store, fn key, store ->
        with {:ok, store} <- store.impl.delete(store, key) do
          store
        else
          error -> throw {:error, error}
        end
      end)
    catch
      {:error, error} -> error
    else
      store -> {:ok, store}
    end
  end

  @callback fetch!(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec fetch!(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)
  def fetch!(store, key) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:raise, store, KeyError, [key: key, term: store.impl]}
        {:ok, value} -> {:ok, store, value}
      end
    end
  end

  @callback get(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec get(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)
  def get(store, key), do: get(store, key, nil)

  @callback get(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec get(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction(Mnemonix.value)
  def get(store, key, default) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:ok, store, default}
        {:ok, value} -> {:ok, store, value}
      end
    end
  end

  @callback get_and_update(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec get_and_update(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  def get_and_update(store, key, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      value = case current do
        :error       -> nil
        {:ok, value} -> value
      end

      case fun.(value) do
        {return, new} -> with {:ok, store} <- store.impl.put(store, key, new) do
          {:ok, store, return}
        end
        :pop          -> with {:ok, store} <- store.impl.delete(store, key) do
          {:ok, store, value}
        end
      end
    end
  end

  @callback get_and_update!(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec get_and_update!(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  def get_and_update!(store, key, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error       -> {:raise, store, KeyError, [key: key, term: store.impl]}
        {:ok, value} -> case fun.(value) do
          {return, new} -> with {:ok, store} <- store.impl.put(store, key, new) do
            {:ok, store, return}
          end
          :pop          -> with {:ok, store, value} <- pop(store, key) do
            {:ok, store, value}
          end
        end
      end
    end
  end

  @callback get_lazy(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec get_lazy(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  def get_lazy(store, key, fun) when is_function(fun, 0) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      value = case current do
        :error       -> fun.()
        {:ok, value} -> value
      end
      {:ok, store, value}
    end
  end

  @callback has_key?(Store.t, Mnemonix.key)
    :: Store.Server.instruction(boolean)
  @doc false
  @spec has_key?(Store.t, Mnemonix.key)
    :: Store.Server.instruction(boolean)
  def has_key?(store, key) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:ok, store, false}
        _value -> {:ok, store, true}
      end
    end
  end

  @callback pop(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec pop(Store.t, Mnemonix.key)
    :: Store.Server.instruction(Mnemonix.value)
  def pop(store, key), do: pop(store, key, nil)

  @callback pop(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec pop(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction(Mnemonix.value)
  def pop(store, key, default) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error       -> {:ok, store, default}
        {:ok, value} -> with {:ok, store} <- store.impl.delete(store, key) do
          {:ok, store, value}
        end
      end
    end
  end

  @callback pop_lazy(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  @doc false
  @spec pop_lazy(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction(Mnemonix.value)
  def pop_lazy(store, key, fun) when is_function(fun, 0) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error       -> {:ok, store, fun.()}
        {:ok, value} -> with {:ok, store} <- store.impl.delete(store, key) do
          {:ok, store, value}
        end
      end
    end
  end

  @callback put_new(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction
  @doc false
  @spec put_new(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction
  def put_new(store, key, value) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> store.impl.put(store, key, value)
        _value -> {:ok, store}
      end
    end
  end

  @callback put_new_lazy(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction
  @doc false
  @spec put_new_lazy(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> store.impl.put(store, key, fun.())
        _value -> {:ok, store}
      end
    end
  end

  @callback replace(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction
  @doc false
  @spec replace(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction
  def replace(store, key, value) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:ok, store}
        _value -> store.impl.put(store, key, value)
      end
    end
  end

  @callback replace!(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction
  @doc false
  @spec replace!(Store.t, Mnemonix.key, Mnemonix.value)
    :: Store.Server.instruction
  def replace!(store, key, value) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:raise, store, KeyError, [key: key, term: store.impl]}
        _value -> store.impl.put(store, key, value)
      end
    end
  end

  @callback split(Store.t, [Mnemonix.key])
    :: Store.Server.instruction([Mnemonix.pair])
  @doc false
  @spec split(Store.t, [Mnemonix.key])
    :: Store.Server.instruction([Mnemonix.pair])
  def split(store, keys) do
    try do
      Enum.reduce(keys, {store, []}, fn key, {store, result} ->
        with {:ok, store, value} <- store.impl.fetch(store, key) do
          case value do
            :error       -> {store, result}
            {:ok, value} -> case store.impl.delete(store, key) do
              {:ok, store} -> {store, Keyword.put(result, key, value)}
              error -> throw {:error, error}
            end
            error -> throw {:error, error}
          end
        else
          error -> throw {:error, error}
        end
      end)
    catch
      {:error, error} -> error
    else
      {store, result} -> {:ok, store, result}
    end
  end

  @callback take(Store.t, [Mnemonix.key])
    :: Store.Server.instruction([Mnemonix.pair])
  @doc false
  @spec take(Store.t, [Mnemonix.key])
    :: Store.Server.instruction([Mnemonix.pair])
  def take(store, keys) do
    try do
      Enum.reduce(keys, {store, []}, fn key, {store, result} ->
        with {:ok, store, value} <- store.impl.fetch(store, key) do
          case value do
            {:ok, value} -> {store, Keyword.put(result, key, value)}
            :error       -> {store, result}
          end
        else
          error -> throw {:error, error}
        end
      end)
    catch
      {:error, error} -> error
    else
      {store, result} -> {:ok, store, result}
    end
  end

  @callback update(Store.t, Mnemonix.key, Mnemonix.value, fun)
    :: Store.Server.instruction
  @doc false
  @spec update(Store.t, Mnemonix.key, Mnemonix.value, fun)
    :: Store.Server.instruction
  def update(store, key, initial, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        {:ok, value} -> store.impl.put(store, key, fun.(value))
        :error       -> store.impl.put(store, key, initial)
      end
    end
  end

  @callback update!(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction
  @doc false
  @spec update!(Store.t, Mnemonix.key, fun)
    :: Store.Server.instruction
  def update!(store, key, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        {:ok, value} -> store.impl.put(store, key, fun.(value))
        :error       -> {:raise, store, KeyError, [key: key, term: store.impl]}
      end
    end
  end

end
