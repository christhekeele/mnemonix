defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  @callback setup(Mnemonix.Store.options)
    :: {:ok, state :: term} | :ignore | {:stop, reason :: term}

  @optional_callbacks setup_initial: 1
  @callback setup_initial(Mnemonix.Store.t)
    :: {:ok, Mnemonix.store} | no_return

  @optional_callbacks serialize_key: 2
  @callback serialize_key(Mnemonix.key, Mnemonix.Store.t)
    :: serialized_key :: term | no_return

  @optional_callbacks serialize_value: 2
  @callback serialize_value(Mnemonix.value, Mnemonix.Store.t)
    :: serialized_value :: term | no_return

  @optional_callbacks deserialize_key: 2
  @callback deserialize_key(serialized_key :: term, Mnemonix.Store.t)
    :: Mnemonix.key :: term | no_return

  @optional_callbacks deserialize_value: 2
  @callback deserialize_value(serialized_value :: term, Mnemonix.Store.t)
    :: Mnemonix.value :: term | no_return

  @optional_callbacks teardown: 2
  @callback teardown(reason, Mnemonix.Store.t)
    :: {:ok, reason} | {:error, reason}
      when reason: :normal | :shutdown | {:shutdown, term} | term

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__

      @doc false
      def setup_initial(store = %Mnemonix.Store{impl: impl, opts: opts}) do
        opts
        |> Keyword.get(:initial, %{})
        |> Enum.reduce({:ok, store}, fn {key, value}, {:ok, store} ->
          impl.put(store, impl.serialize_key(key, store), impl.serialize_value(value, store))
        end)
      end
      defoverridable setup_initial: 1

      @doc false
      def serialize_key(key, store) do
        :erlang.term_to_binary(key, serialization_opts(store))
      end
      defoverridable serialize_key: 2

      @doc false
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
      def deserialize_key(nil, _store) do
        nil
      end
      def deserialize_key(serialized_key, _store) do
        :erlang.binary_to_term(serialized_key, [:safe])
      end
      defoverridable deserialize_key: 2

      @doc false
      def deserialize_value(nil, _store) do
        nil
      end
      def deserialize_value(serialized_value, _store) do
        :erlang.binary_to_term(serialized_value, [:safe])
      end
      defoverridable deserialize_value: 2

      @doc false
      def teardown(reason, _store) do
        {:ok, reason}
      end
      defoverridable teardown: 2
    end
  end

end
