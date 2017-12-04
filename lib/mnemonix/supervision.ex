defmodule Mnemonix.Supervision do
  @moduledoc """
  Functions to start a store server.

  Using this module will define `start_link` functions that allow your module to offer an API for
  booting up a `Mnemonix.Store.Server`.

  Providing a `:default` option will allow you to override the configuration described in
  `Mnemonix.Application.default/0` with your own defaults that are used to expand the arguments given
  to `start_link/0` and `start_link/1` into a fully-specified `start_link/2` call.
  """

  defmacro __using__(opts \\ []) do
    {singleton, opts} = Mnemonix.Singleton.Behaviour.establish_singleton(__CALLER__.module, opts)

    store =
      if singleton,
        do:
          Mnemonix.Singleton.Behaviour.determine_singleton(
            __CALLER__.module,
            Keyword.get(opts, :singleton)
          )

    quote location: :keep do
      alias Mnemonix.Store

      @doc false
      def defaults do
        {default_impl, default_opts} = Mnemonix.Application.specification()

        case Keyword.get(unquote(opts), :default, Mnemonix.Application.specification()) do
          impl when is_atom(impl) -> {impl, default_impl}
          opts when is_list(opts) -> {default_opts, opts}
          {impl, opts} -> {impl, opts}
        end
      end

      @doc """
      Starts a new store using the default store implementation and options.

      The returned `t:GenServer.server/0` reference can be used in the `Mnemonix` API.
      """
      @spec start_link :: GenServer.on_start()
      def start_link do
        {implementation, options} = defaults()
        start_link(implementation, options)
      end

      @doc """
      Starts a new store using the default store implementation and provided `options`.

      ## Examples

          iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.Map)
          iex> Mnemonix.put(store, :foo, :bar)
          iex> Mnemonix.get(store, :foo)
          :bar
      """
      @spec start_link(Store.Server.options()) :: GenServer.on_start()
      def start_link(options) when is_list(options) do
        {implementation, default_options} = defaults()
        start_link(implementation, Keyword.merge(default_options, options))
      end

      @doc """
      Starts a new store using the provided store `implementation` and default options.

      The returned `t:GenServer.server/0` reference can be used in the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = Mnemonix.start_link(Mnemonix.Stores.Map)
          iex> Mnemonix.put(store, :foo, :bar)
          iex> Mnemonix.get(store, :foo)
          :bar
      """
      @spec start_link(Store.Behaviour.t()) :: GenServer.on_start()
      def start_link(implementation) do
        {_implementation, default_options} = defaults()
        start_link(implementation, default_options)
      end

      @doc """
      Starts a new store using the provided store `implementation` and `options`.

      The returned `t:GenServer.server/0` reference can be used in the `Mnemonix` API.

      ## Examples

          iex> options = [initial: %{foo: :bar}, name: NamedStore]
          iex> {:ok, _store} = Mnemonix.start_link(Mnemonix.Stores.Map, options)
          iex> Mnemonix.get(NamedStore, :foo)
          :bar
      """
      @spec start_link(Store.Behaviour.t(), Store.Server.options()) :: GenServer.on_start()
      def start_link(implementation, options) do
        implementation.start_link(Keyword.put_new(options, :name, unquote(store)))
      end
    end
  end
end
