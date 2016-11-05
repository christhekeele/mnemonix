defmodule Mnemonix.Store.Bump.Callbacks do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      ####
      # OPTIONAL
      ##

      @doc false
      def handle_call({:increment, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.increment(store, key) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:increment, key, amount}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.increment(store, key, amount) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:increment!, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.increment!(store, key) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:increment!, key, amount}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.increment!(store, key, amount) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:decrement, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.decrement(store, key) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:decrement, key, amount}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.decrement(store, key, amount) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:decrement!, key}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.decrement!(store, key) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

      @doc false
      def handle_call({:decrement!, key, amount}, _, store = %__MODULE__{adapter: adapter}) do
        case adapter.decrement!(store, key, amount) do
          {:ok, store, value}  -> {:reply, value, store}
          {:raise, type, args} -> {:reply, {:raise, type, args}, store}
        end
      end

    end
  end

end
