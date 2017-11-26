defmodule Mnemonix.Application do
  @moduledoc """
  Automatically starts stores when your application starts.

  Mnemonix can manage your stores for you. To do so, it looks in your config files for named stores:

      config :mnemonix, stores: [:foo, :bar]

  For all stores so listed, it will check for store-specific configuration:

      config :mnemonix, :foo, {Memonix.ETS.Store, [
        store: [table: :my_ets_table],
        server: []
      ]}

  If no configuration is found for a named store, it will use a default configuration
  of `{Mnemonix.Stores.Map, []}`.

  The name of the store in your config will be the reference you pass to `Mnemonix`
  to interact with it.
  Given the config above, `:foo` would refer to an ETS-backed store,
  and `:bar` to a default Map-backed store,
  both available to you at boot time without writing a line of code:

      Application.ensure_started(:mnemonix)

      Mnemonix.put(:foo, :a, :b)
      Mnemonix.get(:foo, :a)
      #=> :b

      Mnemonix.put(:bar, :a, :b)
      Mnemonix.get(:bar, :a)
      #=> :b
  """

  use Application

  @typedoc """
  Default options used by `Mnemonix.start/2` to start stores with no specified config.

  The default options are `[{Mnemonix.Stores.Map, []}]`.
  """
  @type options :: [{Mnemonix.Store.Behaviour.t, Mnemonix.Store.Server.options}]

  @doc """
  Starts the `:mnemonix` application.

  Finds stores in your application configuration and brings them up when your app starts.

  Reads from the `:mnemonix` application `:stores` configuration to detect stores to automatically supervise.

  If a store listed in the configuration has its own entry under the `:mnemonix` application configuration,
  that entry will be used to configure the store.

  ### Examples

      config :mnemonix, stores: [Foo, Bar]
      config :mnemonix, Bar: {Mnemonix.Stores.ETS, server: [name: Baz]}
  """
  @impl Application
  @spec start(Application.start_type, Mnemonix.Application.options)
    :: {:ok, pid} | {:error, reason :: term}
  def start(_type, [default]) do
    :mnemonix
    |> Application.get_env(:stores, [])
    |> Enum.map(fn name ->
      :mnemonix
      |> Application.get_env(name, default)
      |> prepare_child_spec(name)
    end)
    |> Supervisor.start_link(strategy: :one_for_one, name: Mnemonix.Supervisor)
  end

  defp prepare_child_spec({impl, opts}, name) do
    {impl, Keyword.put_new(opts, :name, name)}
  end

  @doc """
  The default Mnemonix.Application options defined in the project's `mix.exs`.

  This is the configuration used for stores named in `config :mnemonix, :stores`
  without corresponding configuration under `config :mnemonix, <name>`.
  """
  def default, do: :mnemonix
    |> Application.spec
    |> Keyword.get(:mod)
    |> elem(1)
    |> List.first

end
