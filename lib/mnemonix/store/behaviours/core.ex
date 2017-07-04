defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  @callback setup(Mnemonix.Store.options)
    :: {:ok, state :: term} | :ignore | {:stop, reason :: term}

  @callback serialize_key(Mnemonix.key, Mnemonix.Store.t)
    :: serialized_key :: term | no_return

  @callback serialize_value(Mnemonix.value, Mnemonix.Store.t)
    :: serialized_value :: term | no_return

  @callback deserialize_key(serialized_key :: term, Mnemonix.Store.t)
    :: Mnemonix.key :: term | no_return

  @callback deserialize_value(serialized_value :: term, Mnemonix.Store.t)
    :: Mnemonix.value :: term | no_return

  @optional_callbacks setup_initial: 1
  @callback setup_initial(Mnemonix.Store.t)
    :: {:ok, Mnemonix.store} | no_return

  @optional_callbacks teardown: 2
  @callback teardown(reason, Mnemonix.Store.t)
    :: {:ok, reason} | {:error, reason}
      when reason: :normal | :shutdown | {:shutdown, term} | term

  @doc false
  defmacro __using__(_) do
    quote do
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
      def teardown(reason, _store) do
        {:ok, reason}
      end
      defoverridable teardown: 2
    end
  end

end
