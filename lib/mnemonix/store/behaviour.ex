defmodule Mnemonix.Store.Behaviour do
  @moduledoc """
  Main point of entry for implementing new Mnemonix.Stores.

  To create new store, you simply use this module as a meta-behaviour that brings in many others.

  It will implement `start_link/1`, `start_link/2`, and `start_link/3` functions
  and bring in the actual `Mnemonix` behaviours:

  - `Mnemonix.Core.Behaviour`: required callbacks with no default implementation a store must provide
  - `Mnemonix.Lifecycle.Behaviour`: support for `c:GenServer:terminate/2`
  - `Mnemonix.Map.Behaviour`: support for map operations
  - `Mnemonix.Expiry.Behaviour`: support for expire/persist operations
  - `Mnemonix.Bump.Behaviour`: support for increment/decrement operations

  These behaviours may have required callbacks you need to implement for the store to work,
  and optional callbacks with default implementations that leverage the required ones to make
  the store fully featured.

  ## Core Callbacks

  Currently the callbacks you must implement for a full-featured store are:

  - `c:Mnemonix.Core.Behaviour.setup/1`
  - `c:Mnemonix.Core.Behaviour.delete/2`
  - `c:Mnemonix.Core.Behaviour.fetch/2`
  - `c:Mnemonix.Core.Behaviour.put/3`

  All other `Mnemonix` functions can be implemented in terms of them.

  ## Optional Callbacks

  Every single `Mnemonix` function/arity combo has a corresponding callback.
  Those that are not required have default implementations, normally in terms of the core ones.
  However, these implementations are all marked as overridable,
  so if the store you are building offers native support for an operation,
  you can call it directly to provide a more efficient implementation.

  If any these callbacks don't make sense to implement in the context of the store you're developing,
  feel free to override them to raise an exception when they are used.
  Most callbacks are expected to return some variant of `{:ok, updated_store, return_value}`,
  but if they return `{:error, ExceptionModule, args}`,
  it will raise the exception at the `Mnemonix` call site,
  keeping the store process alive.

  ## Building a Store

  `Mnemonix.Map.Store` exists mostly to provide a reference implementation for store developers,
  demonstrating the minimum necessary to get a store working.

  `Mnemonix.ETS.Store` is a good example of a store that requires more complicated initialization logic.

  `Mnemonix.Redix.Store` is a good example of a store that overrides optional callbacks
  with native support for `Mnemonix.Expiry.Behaviour` and `Mnemonix.Bump.Behaviour`.

  ## Adding Capabilities to Mnemonix

  Mnemonix is powered by a non-trivial set of interfaces. If you want to contribute functionality
  to the core `Mnemonix` module, you must understand how they all work. Reading the source code
  is the best way to do this, but here's a high level overview.

  ### Mnemonix.Store

  Every `Mnemonix.Store` is just a `GenServer` with a very particular interface and state.

  ### Mnemonix.Store.start_link

  When the store is started, it goes through an initialization pipeline provided by `init/1`.
  First it invokes `c:Mnemonix.Lifecycle.Behaviour.setup/1` to prepare private internal state
  from user-provided options, then it allows utilities to do feature-specific setup in extra callbacks
  like `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`.

  ### The Mnemonix.Store struct

  The state of the `Mnemonix.Store` server, and result of `init/1`, is a struct containing:

  - `impl:` the underlying store module to make calls to
  - `opts:` the options this store was configured with in `init/1`
  - `state:` the store-specific result of `c:Mnemonix.Lifecycle.Behaviour.setup/1`
  - `expiry:` the store-specific result of `c:Mnemonix.Expiry.Behaviour.setup_expiry/1`

  ### `Mnemonix` => `Mnemonix.Store`

  `Mnemonix` functions invoke `GenServer.call/3`.
  """

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      use Mnemonix.Store.Core.Behaviour
      use Mnemonix.Store.Lifecycle.Behaviour
      use Mnemonix.Store.Map.Behaviour
      use Mnemonix.Store.Expiry.Behaviour
      use Mnemonix.Store.Bump.Behaviour

      @store __MODULE__ |> Inspect.inspect(%Inspect.Opts{})

      @doc """
      Starts a new `Mnemonix.Store` using the `#{@store}` module.

      If you wish to pass configuration options to the module instead,
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
      Starts a new `Mnemonix.Store` using the `#{@store}` module
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
