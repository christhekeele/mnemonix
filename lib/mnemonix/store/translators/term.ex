defmodule Mnemonix.Store.Translator.Term do
  @moduledoc false
  # External Term Format serialization/deserialization logic for out-of-memory stores

  defmacro __using__(_) do
    quote do

      @doc false
      @spec serialize_key(Mnemonix.key, Mnemonix.Store.t)
        :: serialized_key :: term | no_return
      def serialize_key(key, store) do
        :erlang.term_to_binary(key, serialization_opts(store))
      end
      defoverridable serialize_key: 2

      @doc false
      @spec serialize_value(Mnemonix.value, Mnemonix.Store.t)
        :: serialized_value :: term | no_return
      def serialize_value(value, store) do
        :erlang.term_to_binary(value, serialization_opts(store))
      end
      defoverridable serialize_value: 2

      defp serialization_opts(%Mnemonix.Store{opts: opts}) do
        case opts[:compression] do
          true -> [:compressed]
          rate when is_integer(rate) -> [compressed: rate]
          _ -> []
        end
      end

      @doc false
      @spec deserialize_key(serialized_key :: term, Mnemonix.Store.t)
        :: Mnemonix.key :: term | no_return
      def deserialize_key(serialized_key, store)
      def deserialize_key(nil, _store) do
        nil
      end
      def deserialize_key(serialized_key, _store) do
        :erlang.binary_to_term(serialized_key, [:safe])
      end
      defoverridable deserialize_key: 2

      @doc false
      @spec deserialize_value(serialized_value :: term, Mnemonix.Store.t)
        :: Mnemonix.value :: term | no_return
      def deserialize_value(serialized_value, store)
      def deserialize_value(nil, _store) do
        nil
      end
      def deserialize_value(serialized_value, _store) do
        :erlang.binary_to_term(serialized_value, [:safe])
      end
      defoverridable deserialize_value: 2

    end
  end
end
