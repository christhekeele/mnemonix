defmodule Mnemonix.Store.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      use Mnemonix.Store.Lifecycle.Behaviour
      use Mnemonix.Store.Map.Behaviour
      use Mnemonix.Store.Bump.Behaviour

      @store __MODULE__ |> Inspect.inspect(%Inspect.Opts{})

      @doc """
      Starts a new `Mnemonix.Store` using the `#{@store}` adapter.

      If you wish to pass configuration options to the adapter instead,
      use `start_link/2` with an empty `opts` list.

      The returned `t:GenServer.server/0` reference can be used as the primary
      argument to the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = #{@store}.start_link
          iex> Mnemonix.put(store, :foo, "bar")
          iex> Mnemonix.fetch(store, :foo)
          {:ok, "bar"}
          iex> Mnemonix.delete(store, :foo)
          iex> Mnemonix.fetch(store, :foo)
          :error
      """
      @spec start_link()                              :: GenServer.on_start
      @spec start_link(GenServer.options)             :: GenServer.on_start
      def start_link(opts \\ []) do
        Mnemonix.Store.start_link(__MODULE__, opts)
      end

      @doc """
      Starts a new `Mnemonix.Store` using the `#{@store}` adapter
       with `init` opts.

      The returned `t:GenServer.server/0` reference can be used as the primary
      argument to the `Mnemonix` API.
      """
      @spec start_link(Mnemonix.Store.opts, GenServer.options) :: GenServer.on_start
      def start_link(init, opts) do
        Mnemonix.Store.start_link({__MODULE__, init}, opts)
      end
    end
  end

end
