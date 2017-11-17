defmodule Mnemonix.Store.Translator.Term do
  @moduledoc false
  # External Term Format serialization/deserialization logic for out-of-memory stores

  defmacro __using__(_) do
    quote location: :keep do

      @impl Mnemonix.Store.Translator
      @spec serialize_key(Mnemonix.Store.t, Mnemonix.key)
        :: term | no_return
      def serialize_key(store, key) do
        :erlang.term_to_binary(key, serialization_opts(store))
      end

      @impl Mnemonix.Store.Translator
      @spec serialize_value(Mnemonix.Store.t, Mnemonix.value)
        :: term | no_return
      def serialize_value(store, value) do
        :erlang.term_to_binary(value, serialization_opts(store))
      end

      @impl Mnemonix.Store.Translator
      @spec deserialize_key(Mnemonix.Store.t, term)
        :: Mnemonix.key | no_return
      def deserialize_key(store, serialized_key)
      def deserialize_key(_store, nil) do
        nil
      end
      def deserialize_key(store, serialized_key) do
        :erlang.binary_to_term(serialized_key, deserialization_opts(store))
      end

      @impl Mnemonix.Store.Translator
      @spec deserialize_value(Mnemonix.Store.t, term)
        :: Mnemonix.value | no_return
      def deserialize_value(store, serialized_value)
      def deserialize_value(_store, nil) do
        nil
      end
      def deserialize_value(store, serialized_value) do
        :erlang.binary_to_term(serialized_value, deserialization_opts(store))
      end

      defp serialization_opts(%Mnemonix.Store{opts: opts}) do
        case opts[:compression] do
          true -> [:compressed]
          rate when is_integer(rate) -> [compressed: rate]
          _ -> []
        end
      end

      defp deserialization_opts(%Mnemonix.Store{opts: opts}) do
        case opts[:safe_term_deserialization] do
          true -> [:safe]
          _    -> []
        end
      end

      defoverridable Mnemonix.Store.Translator

    end
  end
end
