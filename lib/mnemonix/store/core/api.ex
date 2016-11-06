defmodule Mnemonix.Store.Core.API do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc """
      Removes the entry under `key` in `store`.

      If the `key` does not exist, the contents of `store` will be unaffected.

      ## Examples

          iex> store = Mnemonix.new(%{a: 1})
          iex> Mnemonix.get(store, :a)
          1
          iex> Mnemonix.delete(store, :a)
          iex> Mnemonix.get(store, :a)
          nil
      """
      @spec delete(store, key) :: store | no_return
      def delete(store, key) do
        case GenServer.call(store, {:delete, key}) do
          :ok                  -> store
          {:raise, type, args} -> raise type, args
        end
      end

      @doc """
      Retrievs the value of the entry under `key` in `store`.

      If the `key` does not exist, returns `:error`, otherwise returns
      `{:ok, value}`.

      ## Examples

          iex> store = Mnemonix.new(%{a: 1})
          iex> Mnemonix.fetch(store, :a)
          {:ok, 1}
          iex> Mnemonix.fetch(store, :b)
          :error
      """
      @spec fetch(store, key) :: {:ok, value} | :error | no_return
      def fetch(store, key) do
        case GenServer.call(store, {:fetch, key}) do
          {:ok, value}         -> value
          {:raise, type, args} -> raise type, args
        end
      end

      @doc """
      Creates a new entry for `value` under `key` in `store`.

      ## Examples

          iex> store = Mnemonix.new(%{a: 1})
          iex> Mnemonix.get(store, :b)
          nil
          iex> Mnemonix.put(store, :b, 2)
          iex> Mnemonix.get(store, :b)
          2
      """
      @spec put(store, key, value) :: store | no_return
      def put(store, key, value) do
        case GenServer.call(store, {:put, key, value}) do
          :ok                  -> store
          {:raise, type, args} -> raise type, args
        end
      end

    end
  end

end
