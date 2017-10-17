defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  @callback setup(Mnemonix.Store.options)
    :: {:ok, state :: term} | :ignore | {:stop, reason :: term}

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
