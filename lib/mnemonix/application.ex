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

  @doc """
  Starts a Mnemonix.Application with a default configuration. Invoked by `Mnemonix.start/2`.
  """
  @spec start_link(Mnemonix.Store.Server.config)
    :: {:ok, Mnemonix.store} | {:error, reason :: term}
  def start_link(default) do
    :mnemonix
    |> Application.get_env(:stores, [])
    |> Enum.map(fn name ->
      :mnemonix
      |> Application.get_env(name, default)
      |> start_defaults(name)
    end)
    |> Mnemonix.Store.Supervisor.start_link
  end

  defp start_defaults({module, opts}, name) do
    {module, opts
      |> Keyword.put(:otp_app, :mnemonix)
      |> Keyword.put_new(:server, [])
      |> Kernel.put_in([:server, :name], name)
    }
  end

end
