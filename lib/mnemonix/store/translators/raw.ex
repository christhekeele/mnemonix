defmodule Mnemonix.Store.Translator.Raw do
  defmacro __using__(_) do
    quote do
      @doc false
      @spec serialize_key(Mnemonix.key, Mnemonix.Store.t)
        :: serialized_key :: term | no_return
      def serialize_key(key, _store) do
        key
      end

      @doc false
      @spec serialize_value(Mnemonix.value, Mnemonix.Store.t)
        :: serialized_value :: term | no_return
      def serialize_value(value, _store) do
        value
      end

      @doc false
      @spec deserialize_key(serialized_key :: term, Mnemonix.Store.t)
        :: Mnemonix.key :: term | no_return
      def deserialize_key(serialized_key, _store) do
        serialized_key
      end

      @doc false
      @spec deserialize_value(serialized_value :: term, Mnemonix.Store.t)
        :: Mnemonix.value :: term | no_return
      def deserialize_value(serialized_value, _store) do
        serialized_value
      end
    end
  end
end
