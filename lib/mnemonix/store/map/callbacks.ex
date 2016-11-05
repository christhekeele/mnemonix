defmodule Mnemonix.Store.Map.Callbacks do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      ####
      # REQUIRED
      ##

      def handle_call({:delete, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.delete(store, key) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:fetch, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.fetch(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:put, key, value}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.put(store, key, value) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      ####
      # OPTIONAL
      ##

      def handle_call({:fetch!, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.fetch!(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.get(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get, key, default}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.get(store, key, default) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get_and_update, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.get_and_update(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get_and_update!, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.get_and_update!(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:get_lazy, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.get_lazy(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:has_key?, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.has_key?(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:pop, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.pop(store, key) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:pop, key, default}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.pop(store, key, default) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:pop_lazy, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.pop_lazy(store, key, fun) do
          {:ok, store, value}  -> {:reply, {:ok, value}, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:put_new, key, value}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.put_new(store, key, value) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:put_new_lazy, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.put_new_lazy(store, key, fun) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:update, key, initial, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.update(store, key, initial, fun) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      def handle_call({:update!, key, fun}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.update!(store, key, fun) do
          {:ok, store}         -> {:reply, :ok, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

    end
  end

end
