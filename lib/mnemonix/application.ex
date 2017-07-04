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

  @typedoc """
  Default options used by `Mnemonix.start/2` to start stores with no specified config.

  The default options are `[{Mnemonix.Stores.Map, []}]`.
  """
  @type options :: [Mnemonix.Supervisor.config]

  @doc """
  Starts supervision of the Mnemonix.Application.

  Reads from the `:mnemonix` application `:stores` configuration to detect stores to automatically supervise.

  If a store listed in the configuration has its own entry under the `:mnemonix` application configuration,
  that entry will be used to configure the store.

  Otherwise, the provided default config will be used.
  The default config is `{Mnemonix.Stores.Map, []}` and automatically passed in from `Mnemonix.start/2`
  when your application starts.
  """ && false
  @spec start_link({Mnemonix.Store.Behaviour.t, Mnemonix.Supervisor.options})
    :: {:ok, Mnemonix.store} | {:error, reason :: term}
  def start_link({impl, opts}) do
    options = :mnemonix
    |> Application.get_env(:stores, [])
    |> Enum.map(fn name ->
      :mnemonix
      |> Application.get_env(name, [])
      |> start_defaults(name)
      |> Keyword.merge(opts)
    end)
    Mnemonix.start_link(impl, options)
  end

  defp start_defaults(opts, name) do
    opts
    |> Keyword.put(:otp_app, :mnemonix)
    |> Keyword.put_new(:server, [])
    |> Kernel.put_in([:server, :name], name)
  end

end
