defmodule Mnemonix.Supervision do
  @moduledoc false

  defmacro __using__(opts \\ []) do
    {singleton, opts} = Mnemonix.Singleton.Behaviour.establish_singleton(__CALLER__.module, opts)
    store = if singleton, do: Mnemonix.Singleton.Behaviour.determine_singleton(__CALLER__.module, Keyword.get(opts, :singleton))

    quote location: :keep do
      alias Mnemonix.Store

      @doc """
      Starts a new store using the default store implementation and options.

      See `start_link/2` for more control.
      """
      @spec start_link
        :: GenServer.on_start
      def start_link do
        {impl, options} = Mnemonix.Application.default
        start_link impl, options
      end

      @doc """
      Starts a new store using the default store implementation and provided `options`.

      Checks under `config :mnemonix, implementation, [options]` for options:
      see `start_link/2` for a summary of the options you can set there.

      The returned `t:GenServer.server/0` reference can be used in the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.Map)
          iex> Mnemonix.put(store, :foo, :bar)
          iex> Mnemonix.get(store, :foo)
          :bar
      """
      @spec start_link(Store.Server.options)
        :: GenServer.on_start
      def start_link(options) when is_list(options) do
        {impl, default_options} = Mnemonix.Application.default
        start_link impl, Keyword.merge(default_options, options)
      end

      @doc """
      Starts a new store using the provided store `implementation` and default options.

      Checks under `config :mnemonix, implementation, [options]` for options:
      see `start_link/2` for a summary of the options you can set there.

      The returned `t:GenServer.server/0` reference can be used in the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.Map)
          iex> Mnemonix.put(store, :foo, :bar)
          iex> Mnemonix.get(store, :foo)
          :bar
      """
      @spec start_link(Store.Behaviour.t)
        :: GenServer.on_start
      def start_link(impl) do
        {_impl, default_options} = Mnemonix.Application.default
        start_link impl, default_options
      end

      @doc """
      Starts a new store using the provided store `implementation` and `options`.

      Available `options` are:

      - `:store`

        Options to be given to the store on setup. Study the store `implementation` for more information.

      - `:server`

        A keyword list of options to be given to `GenServer.start_link/3`.

      - `:otp_app`

        Fetches more options for the above from `config otp_app, implementation, [options]`, and merges them together.
        If no `otp_app` is specified, will check under `config :mnemonix, implementation, [options]` for default
        options. Options supplied directly to this function always take precedence over any found in
        your configuration.

      The returned `t:GenServer.server/0` reference can be used in the `Mnemonix` API.

      ## Examples

          iex> options = [initial: %{foo: :bar}, name: NamedStore]
          iex> {:ok, _store} = Mnemonix.start_link(Mnemonix.Stores.Map, options)
          iex> Mnemonix.get(NamedStore, :foo)
          :bar
      """
      @spec start_link(Store.Behaviour.t, Store.Server.options)
        :: GenServer.on_start
      def start_link(impl, options) do
        impl.start_link(Keyword.put_new(options, :name, unquote(store)))
      end

    end
  end
end
