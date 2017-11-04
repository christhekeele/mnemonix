defmodule Mnemonix.Store.Translator.Raw do
  @moduledoc false
  # No-op serialization/deserialization logic for in-memory stores

  defmacro __using__(_) do
    quote do

      @impl Mnemonix.Store.Translator
      @spec serialize_key(Mnemonix.Store.t, Mnemonix.key)
        :: term | no_return
      def serialize_key(_store, key) do
        key
      end

      @impl Mnemonix.Store.Translator
      @spec serialize_value(Mnemonix.Store.t, Mnemonix.value)
        :: term | no_return
      def serialize_value(_store, value) do
        value
      end

      @impl Mnemonix.Store.Translator
      @spec deserialize_key(Mnemonix.Store.t, term)
        :: Mnemonix.key | no_return
      def deserialize_key(_store, serialized_key) do
        serialized_key
      end

      @impl Mnemonix.Store.Translator
      @spec deserialize_value(Mnemonix.Store.t, term)
        :: Mnemonix.value | no_return
      def deserialize_value(_store, serialized_value) do
        serialized_value
      end

      defoverridable Mnemonix.Store.Translator

    end
  end
end
