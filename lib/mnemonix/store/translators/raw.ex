defmodule Mnemonix.Store.Translator.Raw do
  @moduledoc false
  # No-op serialization/deserialization logic for in-memory stores

  defmacro __using__(_) do
    quote do

      @doc false
      @spec serialize_key(Mnemonix.Store.t, Mnemonix.key)
        :: term | no_return
      def serialize_key(_store, key) do
        key
      end
      defoverridable serialize_key: 2

      @doc false
      @spec serialize_value(Mnemonix.Store.t, Mnemonix.value)
        :: term | no_return
      def serialize_value(_store, value) do
        value
      end
      defoverridable serialize_value: 2

      @doc false
      @spec deserialize_key(Mnemonix.Store.t, term)
        :: Mnemonix.key | no_return
      def deserialize_key(_store, serialized_key) do
        serialized_key
      end
      defoverridable deserialize_key: 2

      @doc false
      @spec deserialize_value(Mnemonix.Store.t, term)
        :: Mnemonix.value | no_return
      def deserialize_value(_store, serialized_value) do
        serialized_value
      end
      defoverridable deserialize_value: 2

    end
  end
end
