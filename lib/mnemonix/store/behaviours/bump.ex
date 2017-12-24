defmodule Mnemonix.Store.Behaviours.Bump do
  @moduledoc false

  alias Mnemonix.Store
  alias Mnemonix.Features.Bump

  use Mnemonix.Behaviour

  ####
  # DERIVABLE
  ##

  @callback bump(Store.t(), Mnemonix.key(), Bump.amount()) ::
              Store.Server.instruction(Bump.result())
  @doc false
  @spec bump(Store.t(), Mnemonix.key(), Bump.amount()) :: Store.Server.instruction(Bump.result())
  def bump(store, key, amount) do
    with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
      case result do
        {:ok, value} ->
          {:ok, store, {:ok, value}}

        {:error, :no_integer} ->
          {:ok, store, {:ok, {:error, :no_integer}}}
      end
    end
  end

  @callback bump!(Store.t(), Mnemonix.key(), amount :: term) :: Store.Server.instruction()
  @doc false
  @spec bump!(Store.t(), Mnemonix.key(), amount :: term) :: Store.Server.instruction()
  def bump!(store, key, amount) do
    with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
      case result do
        {:ok, _value} ->
          {:ok, store, :ok}

        {:error, :no_integer} ->
          {:raise, store, ArithmeticError, [message: "bad argument in arithmetic expression"]}
      end
    end
  end

  @callback increment(Store.t(), Mnemonix.key()) :: Store.Server.instruction()
  @doc false
  @spec increment(Store.t(), Mnemonix.key()) :: Store.Server.instruction()
  def increment(store, key), do: increment(store, key, 1)

  @callback increment(Store.t(), Mnemonix.key(), amount :: term) :: Store.Server.instruction()
  @doc false
  @spec increment(Store.t(), Mnemonix.key(), amount :: term) :: Store.Server.instruction()
  def increment(store, key, amount) do
    with {:ok, store, result} <- do_bump(store, :increment, key, amount) do
      case result do
        {:ok, value} ->
          {:ok, store, {:ok, value}}

        {:error, :no_integer} ->
          {:ok, store, {:ok, {:error, :no_integer}}}
      end
    end
  end

  @callback decrement(Store.t(), Mnemonix.key()) :: Store.Server.instruction()
  @doc false
  @spec decrement(Store.t(), Mnemonix.key()) :: Store.Server.instruction()
  def decrement(store, key), do: decrement(store, key, 1)

  @callback decrement(Store.t(), Mnemonix.key(), amount :: term) :: Store.Server.instruction()
  @doc false
  @spec decrement(Store.t(), Mnemonix.key(), amount :: term) :: Store.Server.instruction()
  def decrement(store, key, amount) do
    with {:ok, store, result} <- do_bump(store, :decrement, key, amount) do
      case result do
        {:ok, value} ->
          {:ok, store, {:ok, value}}

        {:error, :no_integer} ->
          {:ok, store, {:ok, {:error, :no_integer}}}
      end
    end
  end

  defp do_bump(store, operation, key, amount) do
    if is_integer(amount) do
      with {:ok, store, current} <- store.impl.fetch(store, key) do
        case current do
          :error ->
            with {:ok, store} <- store.impl.put(store, key, store.impl.serialize_value(store, 0)) do
              do_bump(store, operation, key, amount)
            end

          {:ok, value} ->
            case do_bump_calculation(operation, store.impl.deserialize_value(store, value), amount) do
              {:ok, value} ->
                with {:ok, store} <-
                       store.impl.put(store, key, store.impl.serialize_value(store, value)) do
                  {:ok, store, {:ok, value}}
                end

              {:error, :no_integer} ->
                {:ok, store, {:error, :no_integer}}
            end
        end
      end
    else
      {:ok, store, {:error, :no_integer}}
    end
  end

  defp do_bump_calculation(operation, value, amount) do
    if is_integer(value) and is_integer(amount) do
      case operation do
        :increment -> {:ok, value + amount}
        :decrement -> {:ok, value - amount}
      end
    else
      {:error, :no_integer}
    end
  end

end
