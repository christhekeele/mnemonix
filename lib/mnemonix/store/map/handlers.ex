defmodule Mnemonix.Store.Map.Handlers do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      def handle_call({:fetch!, key}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.fetch!(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get, key}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.get(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get, key, default}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.get(store, key, default) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get_and_update, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.get_and_update(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get_and_update!, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.get_and_update!(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.get_lazy(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:has_key?, key}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.has_key?(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:pop, key}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.pop(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:pop, key, default}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.pop(store, key, default) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:pop_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.pop_lazy(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:put_new, key, value}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.put_new(store, key, value) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:put_new_lazy, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.put_new_lazy(store, key, fun) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:update, key, initial, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.update(store, key, initial, fun) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:update!, key, fun}, _, store = %Mnemonix.Store{impl: impl}) do
        case impl.update!(store, key, fun) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

    end
  end

end
