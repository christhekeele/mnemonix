defmodule Mnemonix.Supervision.Standard do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote location: :keep do

      @doc """
      Starts a new store using the default store implementation and options.

      See `start_link/2` for more control.
      """
      @spec start_link
        :: GenServer.on_start
      def start_link do
        start_link __MODULE__, []
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
      @spec start_link(Mnemonix.Store.Behaviour.t)
        :: GenServer.on_start
      def start_link(options) when is_list(options) do
        start_link __MODULE__, options
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
      @spec start_link(Mnemonix.Store.Behaviour.t)
        :: GenServer.on_start
      def start_link(impl) do
        start_link impl, []
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
      @spec start_link(Mnemonix.Store.Behaviour.t, Mnemonix.Supervisor.options)
        :: GenServer.on_start
      def start_link(impl, options) do
        impl.start_link options
      end

    end
  end
end
