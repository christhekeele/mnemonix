defmodule Mnemonix.Supervision.Singleton do
  @moduledoc false
  defmacro __using__(opts \\ []) do

    store = Mnemonix.Singleton.Behaviour.determine_singleton(__CALLER__.module, Keyword.get(opts, :singleton))

    quote location: :keep do

      @doc false
      def start_link do
        start_link __MODULE__, []
      end

      @doc false
      def start_link(opts) when is_list(opts) do
        start_link(__MODULE__, opts)
      end

      @doc false
      def start_link(impl) do
        start_link(impl, [])
      end

      @doc false
      def start_link(impl, opts) do
        impl.start_link(Keyword.put_new(opts, :name, unquote(store)))
      end

    end

  end
end
