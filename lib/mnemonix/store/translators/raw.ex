defmodule Mnemonix.Store.Translator.Raw do
  @moduledoc false
  # No-op serialization/deserialization logic for in-memory stores

  defmacro __using__(_) do
    quote do

      @doc false
      @spec serialize_key(Mnemonix.key, Mnemonix.Store.t)
        :: serialized_key :: term | no_return
      def serialize_key(key, _store) do
        key
      end
      defoverridable serialize_key: 2

      @doc false
      @spec serialize_value(Mnemonix.value, Mnemonix.Store.t)
        :: serialized_value :: term | no_return
      def serialize_value(value, _store) do
        value
      end
      defoverridable serialize_value: 2

      @doc false
      @spec deserialize_key(serialized_key :: term, Mnemonix.Store.t)
        :: Mnemonix.key :: term | no_return
      def deserialize_key(serialized_key, _store) do
        serialized_key
      end
      defoverridable deserialize_key: 2

      @doc false
      @spec deserialize_value(serialized_value :: term, Mnemonix.Store.t)
        :: Mnemonix.value :: term | no_return
      def deserialize_value(serialized_value, _store) do
        serialized_value
      end
      defoverridable deserialize_value: 2

    end
  end
end
