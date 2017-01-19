defmodule Mnemonix.Store.Behaviours.Bump do
  @moduledoc false

  use Mnemonix.Store.Types, [:store, :key, :bump_op, :exception]

  @optional_callbacks bump: 3
  @callback bump(store, key, amount :: term) :: {:ok, store, bump_op} | exception

  @optional_callbacks bump!: 3
  @callback bump!(store, key, amount :: term) :: {:ok, store} | exception

  @optional_callbacks increment: 2
  @callback increment(store, key) :: {:ok, store} | exception

  @optional_callbacks increment: 3
  @callback increment(store, key, amount :: term) :: {:ok, store} | exception

  @optional_callbacks decrement: 2
  @callback decrement(store, key) :: {:ok, store} | exception

  @optional_callbacks decrement: 3
  @callback decrement(store, key, amount :: term) :: {:ok, store} | exception

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @behaviour unquote __MODULE__

      @doc false
      def bump(store, key, amount) do
        with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
          case result do
            :ok                  -> {:ok, store, :ok}
            {:error, no_integer} -> {:ok, store, {:error, :no_integer}}
          end
        end
      end
      defoverridable bump: 3

      @doc false
      def bump!(store, key, amount) do
        with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
          case result do
            :ok                  -> {:ok, store}
            {:error, no_integer} -> {:raise, ArithmeticError, [message: msg_for(no_integer, key)]}
          end
        end
      end
      defoverridable bump!: 3

      defp msg_for(:amount, _key), do: "value provided to operation is not an integer"
      defp msg_for(:value, key),   do: "value at key #{Inspect.inspect(key, %Inspect.Opts{})} is not an integer"

      @doc false
      def increment(store, key, amount \\ 1) do
        with {:ok, store, _result} <- do_bump(store, :increment, key, amount) do
          {:ok, store}
        end
      end
      defoverridable increment: 2, increment: 3

      @doc false
      def decrement(store, key, amount \\ 1) do
        with {:ok, store, _result} <- do_bump(store, :decrement, key, amount) do
          {:ok, store}
        end
      end
      defoverridable decrement: 2, decrement: 3

      defp do_bump(store, operation, key, amount) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> with {:ok, store} <- put(store, key, 0) do
              do_bump(store, operation, key, amount)
            end
            {:ok, value} -> case do_bump_calculation(operation, value, amount) do
              {:ok, result} -> with {:ok, store} <- put(store, key, result) do
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

      defp do_bump_error(store, key, no_integer, raise?) do
        if raise? do
          message = case no_integer do
            :amount -> "value provided to operation is not an integer"
            :value  -> "value at key #{Inspect.inspect(key, %Inspect.Opts{})} is not an integer"
          end
          {:raise, ArithmeticError, [message: message]}
        else
          {:ok, store, {:error, :no_integer}}
        end
      end

    end
  end

end
