defmodule Mnemonix.Store.Behaviour do
  @moduledoc false

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type t :: Module.t

  @typedoc """
  An instruction to the `Mnemonix.Store.Server` to raise an error in the client.
  """
  @type exception :: {:raise, Module.t, raise_opts :: Keyword.t}

  @doc false
  defmacro __using__(opts) do
    docs = Keyword.get(opts, :docs, true)

    quote bind_quoted: [docs: docs] do

      use Mnemonix.Store.Behaviours.Core

      use Mnemonix.Store.Behaviours.Map
      use Mnemonix.Store.Behaviours.Bump
      use Mnemonix.Store.Behaviours.Expiry
      use Mnemonix.Store.Behaviours.Enumerable

      @behaviour Mnemonix.Store.Translator

      @store __MODULE__ |> Inspect.inspect(%Inspect.Opts{})

      if docs do
        @doc """
        Starts a new store using the `#{@store}` module with `options`.

        The `options` are the same as described in `Mnemonix.Features.Supervision.start_link/2`.
        The `:store` options are used in `config/1` to start the store;
        the `:server` options are passed directly to `GenServer.start_link/2`.

        The returned `t:GenServer.server/0` reference can be used as the primary
        argument to the `Mnemonix` API.

        ## Examples

            iex> {:ok, store} = #{@store}.start_link()
            iex> Mnemonix.put(store, "foo", "bar")
            iex> Mnemonix.get(store, "foo")
            "bar"

            iex> {:ok, _store} = #{@store}.start_link(server: [name: My.#{@store}])
            iex> Mnemonix.put(My.#{@store}, "foo", "bar")
            iex> Mnemonix.get(My.#{@store}, "foo")
            "bar"
        """
      end
      @spec start_link()                              :: GenServer.on_start
      @spec start_link(Mnemonix.Supervisor.options) :: GenServer.on_start
      def start_link(options \\ []) do
        Mnemonix.start_link(__MODULE__, options)
      end
      defoverridable start_link: 0, start_link: 1

      if docs do
        @doc """
        Starts a new store using `#{@store}` with `store` and `server` options.

        The options are the same as described in `Mnemonix.start_link/2`.
        The `store` options are used in `config/1` to start the store;
        the `server` options are passed directly to `GenServer.start_link/2`.

        The returned `t:GenServer.server/0` reference can be used as the primary
        argument to the `Mnemonix` API.

        ## Examples

            iex> {:ok, store} = #{@store}.start_link([], [])
            iex> Mnemonix.put(store, "foo", "bar")
            iex> Mnemonix.get(store, "foo")
            "bar"

            iex> {:ok, _store} = #{@store}.start_link([], [name: My.#{@store}])
            iex> Mnemonix.put(My.#{@store}, "foo", "bar")
            iex> Mnemonix.get(My.#{@store}, "foo")
            "bar"
        """
      end
      @spec start_link(Mnemonix.Supervisor.options, GenServer.options) :: GenServer.on_start
      def start_link(store, server) do
        Mnemonix.Store.Server.start_link(__MODULE__, store, server)
      end
      defoverridable start_link: 2

    end
  end

end
