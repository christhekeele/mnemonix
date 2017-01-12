defmodule Mnemonix.Store.Core.Handlers do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      def handle_call({:delete, key}, _, store = %__MODULE__{impl: impl}) do
        case impl.delete(store, key) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:fetch, key}, _, store = %__MODULE__{impl: impl}) do
        case impl.fetch(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:put, key, value}, _, store = %__MODULE__{impl: impl}) do
        case impl.put(store, key, value) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

    end
  end

end
