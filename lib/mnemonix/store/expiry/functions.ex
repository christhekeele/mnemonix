defmodule Mnemonix.Store.Expiry.Functions do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false
      def setup_expiry(store) do
        {:ok, store}
      end
      defoverridable setup_expiry: 1

      @doc false
      def expires(store = %Mnemonix.Store{impl: impl}, _key, _ttl) do
        {:ok, store}
        # {:raise, Exception, [message: "#{impl} doesn't support that"]}
      end
      defoverridable expires: 3

      @doc false
      def persist(store = %Mnemonix.Store{impl: impl}, _key) do
        {:ok, store}
        # {:raise, Exception, [message: "#{impl} doesn't support that"]}
      end
      defoverridable persist: 2

    end
  end

end
