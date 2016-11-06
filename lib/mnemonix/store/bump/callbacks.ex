defmodule Mnemonix.Store.Bump.Callbacks do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false
      def handle_call({:bump, key, amount}, _, store = %__MODULE__{impl: impl}) do
        case impl.bump(store, key, amount) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:bump!, key, amount}, _, store = %__MODULE__{impl: impl}) do
        case impl.bump!(store, key, amount) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:increment, key}, _, store = %__MODULE__{impl: impl}) do
        case impl.increment(store, key) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:increment, key, amount}, _, store = %__MODULE__{impl: impl}) do
        case impl.increment(store, key, amount) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:decrement, key}, _, store = %__MODULE__{impl: impl}) do
        case impl.decrement(store, key) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:decrement, key, amount}, _, store = %__MODULE__{impl: impl}) do
        case impl.decrement(store, key, amount) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

    end
  end

end
