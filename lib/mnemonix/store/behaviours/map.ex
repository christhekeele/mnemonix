defmodule Mnemonix.Store.Behaviours.Map do
  @moduledoc false

  use Mnemonix.Behaviour

####
# MANDATORY
##

  @callback delete(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback fetch(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception

  @callback put(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

####
# DERIVABLE
##

  @callback drop(Mnemonix.Store.t, [Mnemonix.key])
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec drop(Mnemonix.Store.t, [Mnemonix.key])
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
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

  @callback fetch!(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec fetch!(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  def fetch!(store, key) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:raise, KeyError, [key: key, term: store.impl]}
        {:ok, value} -> {:ok, store, value}
      end
    end
  end

  @callback get(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec get(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  def get(store, key), do: get(store, key, nil)

  @callback get(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec get(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  def get(store, key, default) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:ok, store, default}
        {:ok, value} -> {:ok, store, value}
      end
    end
  end

  @callback get_and_update(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec get_and_update(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
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

  @callback get_and_update!(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec get_and_update!(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  def get_and_update!(store, key, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error       -> {:raise, KeyError, [key: key, term: store.impl]}
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

  @callback get_lazy(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec get_lazy(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  def get_lazy(store, key, fun) when is_function(fun, 0) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      value = case current do
        :error       -> fun.()
        {:ok, value} -> value
      end
      {:ok, store, value}
    end
  end

  @callback has_key?(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec has_key?(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception
  def has_key?(store, key) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:ok, store, false}
        _value -> {:ok, store, true}
      end
    end
  end

  @callback pop(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec pop(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  def pop(store, key), do: pop(store, key, nil)

  @callback pop(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec pop(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
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

  @callback pop_lazy(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec pop_lazy(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t, Mnemonix.value} | Mnemonix.Store.Behaviour.exception
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

  @callback put_new(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec put_new(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def put_new(store, key, value) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> store.impl.put(store, key, value)
        _value -> {:ok, store}
      end
    end
  end

  @callback put_new_lazy(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec put_new_lazy(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def put_new_lazy(store, key, fun) when is_function(fun, 0) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> store.impl.put(store, key, fun.())
        _value -> {:ok, store}
      end
    end
  end

  @callback replace(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec replace(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def replace(store, key, value) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:ok, store}
        _value -> store.impl.put(store, key, value)
      end
    end
  end

  @callback replace!(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec replace!(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def replace!(store, key, value) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> {:raise, KeyError, [key: key, term: store.impl]}
        _value -> store.impl.put(store, key, value)
      end
    end
  end

  @callback split(Mnemonix.Store.t, [Mnemonix.key])
    :: {:ok, Mnemonix.Store.t, %{Mnemonix.key => Mnemonix.value}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec split(Mnemonix.Store.t, [Mnemonix.key])
    :: {:ok, Mnemonix.Store.t, %{Mnemonix.key => Mnemonix.value}} | Mnemonix.Store.Behaviour.exception
  def split(store, keys) do
    try do
      Enum.reduce(keys, {store, %{}}, fn key, {store, result} ->
        with {:ok, store, value} <- store.impl.fetch(store, key) do
          case value do
            :error       -> {store, result}
            {:ok, value} -> case store.impl.delete(store, key) do
              {:ok, store} -> {store, Map.put(result, key, value)}
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

  @callback take(Mnemonix.Store.t, [Mnemonix.key])
    :: {:ok, Mnemonix.Store.t, %{Mnemonix.key => Mnemonix.value}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec take(Mnemonix.Store.t, [Mnemonix.key])
    :: {:ok, Mnemonix.Store.t, %{Mnemonix.key => Mnemonix.value}} | Mnemonix.Store.Behaviour.exception
  def take(store, keys) do
    try do
      Enum.reduce(keys, {store, %{}}, fn key, {store, result} ->
        with {:ok, store, value} <- store.impl.fetch(store, key) do
          case value do
            {:ok, value} -> {store, Map.put(result, key, value)}
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

  @callback update(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value, fun)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec update(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value, fun)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def update(store, key, initial, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        {:ok, value} -> store.impl.put(store, key, fun.(value))
        :error       -> store.impl.put(store, key, initial)
      end
    end
  end

  @callback update!(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec update!(Mnemonix.Store.t, Mnemonix.key, fun)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def update!(store, key, fun) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        {:ok, value} -> store.impl.put(store, key, fun.(value))
        :error       -> {:raise, KeyError, [key: key, term: store.impl]}
      end
    end
  end

end
