defmodule Mnemonix.Store.Behaviour do
  @moduledoc """
  Main point of entry for implementing new Mnemonix.Stores.

  To create new store, you simply use this module.

  It will implement `start_link/1`, `start_link/2`, and `start_link/3` functions and bring in the
  actual `Mnemonix` behaviours:

  - `Mnemonix.Lifecycle.Behaviour`: support for `c:GenServer:init/1` and `c:GenServer:terminate/2`
  - `Mnemonix.Map.Behaviour`: support for map operations
  - `Mnemonix.Bump.Behaviour`: support for increment/decrement operations

      iex> defmodule MyMapStore

  Optional callbacks have default implementations in terms of the required ones,
  but are overridable so that adapters can offer optimized versions
  where possible.
  """

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
