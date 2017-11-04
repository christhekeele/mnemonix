defmodule Mnemonix.Store.Behaviours.Bump do
  @moduledoc false

  @callback bump(Mnemonix.Store.t, Mnemonix.key, Mnemonix.amount :: term)
    :: {:ok, Mnemonix.Store.t, Mnemonix.Features.Bump.bump_op} | Mnemonix.Store.Behaviour.exception

  @callback bump!(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback increment(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback increment(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback decrement(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback decrement(Mnemonix.Store.t, Mnemonix.key, amount :: term)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour unquote __MODULE__

      @impl unquote __MODULE__
      def bump(store, key, amount) do
        with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
          case result do
            :ok                  -> {:ok, store, :ok}
            {:error, no_integer} -> {:ok, store, {:error, :no_integer}}
          end
        end
      end

      @impl unquote __MODULE__
      def bump!(store, key, amount) do
        with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
          case result do
            :ok                  -> {:ok, store}
            {:error, no_integer} -> {:raise, ArithmeticError, [message: msg_for(no_integer, store.impl.deserialize_key(store, key))]}
          end
        end
      end

      @impl unquote __MODULE__
      def increment(store, key, amount \\ 1) do
        with {:ok, store, _result} <- do_bump(store, :increment, key, amount) do
          {:ok, store}
        end
      end

      @impl unquote __MODULE__
      def decrement(store, key, amount \\ 1) do
        with {:ok, store, _result} <- do_bump(store, :decrement, key, amount) do
          {:ok, store}
        end
      end

      defp msg_for(:amount, _key), do: "value provided to operation is not an integer"
      defp msg_for(:value, key),   do: "value at key #{key |> Inspect.inspect(%Inspect.Opts{})} is not an integer"

      defp do_bump(store, operation, key, amount) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> with {:ok, store} <- put(store, key, store.impl.serialize_value(store, 0)) do
              do_bump(store, operation, key, amount)
            end
            {:ok, value} -> case do_bump_calculation(operation, store.impl.deserialize_value(store, value), amount) do
              {:ok, result} -> with {:ok, store} <- put(store, key, store.impl.serialize_value(store, result)) do
                {:ok, store, :ok}
              end
              {:error, no_integer} -> {:ok, store, {:error, no_integer}}
            end
          end
        end
      end

      defp do_bump_calculation(_operation, _value, amount) when not is_integer(amount), do: {:error, :amount}
      defp do_bump_calculation(_operation, value, _amount) when not is_integer(value),  do: {:error, :value}

      defp do_bump_calculation(:increment, value, amount), do: {:ok, value + amount}
      defp do_bump_calculation(:decrement, value, amount), do: {:ok, value - amount}

    end
  end

end
