defmodule Mnemonix.Application do
  @moduledoc """
  Automatically starts stores when your application starts.

  Mnemonix can manage your stores for you. To do so, it looks in your config files for named stores:

      config :mnemonix, stores: [:foo, :bar]

  For all stores so listed, it will check for store-specific configuration:

      config :mnemonix, :foo, {Memonix.ETS.Store, table: :my_ets_table, name: :my_ets}

  If no configuration is found for a named store, it will use the default configuration specified
  in `default/0`.

  The name of the store in your config will be the reference you pass to `Mnemonix` to interact with it.
  This can be overriden by providing a `:name` in the options.

  Given the config above, `:foo` would refer to a default Map-backed store,
  and `:bar` to an ETS-backed store named `:my_ets` that uses a table named `:my_ets_table`,
  both available to you at boot time without writing a line of code:

      Application.ensure_started(:mnemonix)

      Mnemonix.put(:foo, :a, :b)
      Mnemonix.get(:foo, :a)
      #=> :b

      Mnemonix.put(:my_ets, :a, :b)
      Mnemonix.get(:my_ets, :a)
      #=> :b
  """

  use Application

  @doc """
  Starts the `:mnemonix` application.

  Finds stores in your application configuration and brings them up when your app starts.

  Reads from the `:mnemonix` application's `:stores` configuration
  to detect store specifications to automatically supervise.

  If a store named in the configuration has its own entry under the `:mnemonix` application configuration,
  that specification will be used to configure the store. If no specification is provided, Mnemonix will use
  the `default` specification documented in `default/0`.

  ### Examples

      config :mnemonix, stores: [Foo, Bar]
      config :mnemonix, Bar: {Mnemonix.Stores.ETS, table: Baz}
  """
  @impl Application
  @spec start(Application.start_type(), [Mnemonix.spec()]) ::
          {:ok, pid} | {:error, reason :: term}
  def start(_type, [default]) do
    default
    |> tree
    |> Supervisor.start_link(name: Mnemonix.Supervisor, strategy: :rest_for_one)
  end

  @spec tree() :: [:supervisor.child_spec()]
  def tree, do: specification() |> tree

  @spec tree(Mnemonix.spec()) :: [:supervisor.child_spec()]
  def tree(default), do: [
    # prepare_supervisor_spec(
    #   Mnemonix.Application.Supervisor,
    #   [
    #     prepare_supervisor_spec(
    #       Mnemonix.Store.Expiry.Supervisor,
    #       [Mnemonix.Store.Expiry.Engine],
    #       strategy: :simple_one_for_one,
    #     )
    #   ],
    #   strategy: :one_for_one,
    # ),
    prepare_supervisor_spec(
      Mnemonix.Store.Supervisor,
      managed_stores(default),
      strategy: :one_for_one,
    ),
  ]

  defp prepare_supervisor_spec(module, children, opts) do
    %{
      id: module,
      start: {Supervisor, :start_link, [children, Keyword.put(opts, :name, module)]},
      restart: :permanent,
      type: :supervisor,
    }
  end

  @doc """
  Convenience function to preview the stores that `Mnemonix.Application` will manage for you.
  """
  @spec managed_stores :: [Supervisor.child_spec()]
  def managed_stores, do: specification() |> managed_stores

  @doc """
  Convenience function to see the configuration of the stores that `Mnemonix.Application` manages for you.

  Provide a store specification to compare the generated configuration against
  the `default` `specification/0` that Mnemonix uses by default.
  """
  @spec managed_stores(Mnemonix.spec()) :: [Supervisor.child_spec()]
  def managed_stores(default) do
    :mnemonix
    |> Application.get_env(:stores, [])
    |> Enum.map(fn name ->
         :mnemonix
         |> Application.get_env(name, default)
         |> prepare_child_spec(name)
       end)
  end

  defp prepare_child_spec({impl, opts}, name) do
    {impl, Keyword.put_new(opts, :name, name)}
  end

  @doc """
  Convenience function to access the default `Mnemonix` store specification defined in its `mix.exs`.

  This is the specification used for stores named in `config :mnemonix, :stores`
  without corresponding configuration under `config :mnemonix, <store_name>`.
  """
  @spec specification :: Mnemonix.spec()
  def specification do
    :mnemonix
    |> Application.spec()
    |> Keyword.get(:mod)
    |> elem(1)
    |> List.first()
  end

  @doc """
  Convenience function to access the current hex version of the `Mnemonix` application.
  """
  def version do
    with {:ok, version} = :application.get_key(:mnemonix, :vsn), do: version
  end
end
