defmodule Mnemonix.Store.Behaviours.Bump do
  @moduledoc false

  use Mnemonix.Behaviour

####
# DERIVABLE
##

  @callback bump(Mnemonix.Store.t, Mnemonix.key, Mnemonix.amount :: term)
    :: {:ok, Mnemonix.Store.t, Mnemonix.Features.Bump.bump_op} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec bump(Mnemonix.Store.t, Mnemonix.key, Mnemonix.amount :: term)
    :: {:ok, Mnemonix.Store.t, Mnemonix.Features.Bump.bump_op} | Mnemonix.Store.Behaviour.exception
  def bump(store, key, amount) do
    with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
      case result do
        :ok                  -> {:ok, store, :ok}
        {:error, no_integer} -> {:ok, store, {:error, no_integer}}
      end
    end
  end

  @callback bump!(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec bump!(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def bump!(store, key, amount) do
    with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
      case result do
        :ok                  -> {:ok, store}
        {:error, no_integer} -> {:raise, ArithmeticError, [message: msg_for(no_integer, store.impl.deserialize_key(store, key))]}
      end
    end
  end

  @callback increment(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec increment(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def increment(store, key), do: increment(store, key, 1)

  @callback increment(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec increment(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def increment(store, key, amount) do
    with {:ok, store, _result} <- do_bump(store, :increment, key, amount) do
      {:ok, store}
    end
  end

  @callback decrement(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec decrement(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def decrement(store, key), do: decrement(store, key, 1)

  @callback decrement(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec decrement(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  def decrement(store, key, amount) do
    with {:ok, store, _result} <- do_bump(store, :decrement, key, amount) do
      {:ok, store}
    end
  end

  @doc false
  def msg_for(:amount, _key), do: "value provided to operation is not an integer"
  def msg_for(:value, key),   do: "value at key #{key |> Inspect.inspect(%Inspect.Opts{})} is not an integer"

  @doc false
  def do_bump(store, operation, key, amount) do
    with {:ok, store, current} <- store.impl.fetch(store, key) do
      case current do
        :error -> with {:ok, store} <- store.impl.put(store, key, store.impl.serialize_value(store, 0)) do
          do_bump(store, operation, key, amount)
        end
        {:ok, value} -> case do_bump_calculation(operation, store.impl.deserialize_value(store, value), amount) do
          {:ok, result} -> with {:ok, store} <- store.impl.put(store, key, store.impl.serialize_value(store, result)) do
            {:ok, store, :ok}
          end
          {:error, no_integer} -> {:ok, store, {:error, no_integer}}
        end
      end
    end
  end

  @doc false

  def do_bump_calculation(_operation, _value, amount) when not is_integer(amount), do: {:error, :amount}
  def do_bump_calculation(_operation, value, _amount) when not is_integer(value),  do: {:error, :value}

  def do_bump_calculation(:increment, value, amount), do: {:ok, value + amount}
  def do_bump_calculation(:decrement, value, amount), do: {:ok, value - amount}

end
