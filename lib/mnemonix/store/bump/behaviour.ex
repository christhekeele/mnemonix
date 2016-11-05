defmodule Mnemonix.Store.Bump.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Bump.Functions
    end
  end

  alias Mnemonix.Store

  @typep store :: Store.t
  @typep key   :: Store.key
  @typep value :: Store.value

  @typep amount :: term

  @typep exception :: Exception.t
  @typep info      :: term


  ####
  # OPTIONAL
  ##

  @optional_callbacks increment: 2
  @doc """
  Increments the value of the integer entry under `key` in `store` by `1`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If the value under `key` is not an integer, returns `{:error, :no_integer}`, otherwise returns `:ok`.
  """
  @callback increment(store, key) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks increment: 3
  @doc """
  Increments the value of the integer entry under `key` in `store` by `amount`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If `amount` or the value under `key` is not an integer, returns `{:error, :no_integer}`, otherwise returns `:ok`.
  """
  @callback increment(store, key, amount) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks increment!: 2
  @doc """
  Increments the value of the integer entry under `key` in `store` by `1`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If the value under `key` is not an integer, raises an `ArithmeticError`.
  """
  @callback increment!(store, key) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks increment!: 3
  @doc """
  Increments the value of the integer entry under `key` in `store` by `amount`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If `amount` or the value under `key` is not an integer, raises an `ArithmeticError`.
  """
  @callback increment!(store, key, amount) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks decrement: 2
  @doc """
  Decrements the value of the integer entry under `key` in `store` by `1`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If the value under `key` is not an integer, returns `{:error, :no_integer}`, otherwise returns `:ok`.
  """
  @callback decrement(store, key) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks decrement: 3
  @doc """
  Decrements the value of the integer entry under `key` in `store` by `amount`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If `amount` or the value under `key` is not an integer, returns `{:error, :no_integer}`, otherwise returns `:ok`.
  """
  @callback decrement(store, key, amount) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks decrement!: 2
  @doc """
  Decrements the value of the integer entry under `key` in `store` by `1`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If the value under `key` is not an integer, raises an `ArithmeticError`.
  """
  @callback decrement!(store, key) ::
    {:ok, store, value} |
    {:raise, exception, info}

  @optional_callbacks decrement!: 3
  @doc """
  Decrements the value of the integer entry under `key` in `store` by `amount`.

  If the `key` does not exist, it is set to `0` before performing the operation.

  If `amount` or the value under `key` is not an integer, raises an `ArithmeticError`.
  """
  @callback decrement!(store, key, amount) ::
    {:ok, store, value} |
    {:raise, exception, info}

end
