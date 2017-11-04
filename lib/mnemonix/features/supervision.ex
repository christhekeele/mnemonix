defmodule Mnemonix.Features.Supervision do
  @moduledoc """
  Functions that allow supervision of a store.

  This is normally the module you will be working with once you've selected your desired store
  implementation and want to insert it properly into a supervision tree.

  The options here will allow you to specify your store type, keep your store always available, and
  decide on the process name for others to recognize it by, if any.

  If you want to play around with the Mnemonix API first, see `Mnemonix.new/0`.

  All of these functions are available on the main `Mnemonix` module.
  """

  defmacro __using__(opts) do
    quote do
      use Mnemonix.Feature, [unquote_splicing(opts), module: unquote(__MODULE__)]
    end
  end

  @doc """
  Starts a new store using the default store implementation and options.

  See `start_link/2` for more control.
  """
  @spec start_link :: GenServer.on_start
  def start_link do
    {implementation, options} = Mnemonix.Application.default
    start_link implementation, options
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
  @spec start_link(Mnemonix.Store.Behaviour.t) :: GenServer.on_start
  def start_link(implementation) do
    start_link implementation, []
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

      iex> options = [store: [initial: %{foo: :bar}], server: [name: NamedStore]]
      iex> {:ok, _store} = Mnemonix.start_link(Mnemonix.Stores.Map, options)
      iex> Mnemonix.get(NamedStore, :foo)
      :bar
  """
  @spec start_link(Mnemonix.Store.Behaviour.t, Mnemonix.Supervisor.options) :: GenServer.on_start
  def start_link(implementation, options) do
    config = options
    |> Keyword.get(:otp_app, :mnemonix)
    |> Application.get_env(implementation, [])
    [store, server] = for option <- [:store, :server] do
      config
      |> Keyword.get(option, [])
      |> Keyword.merge(Keyword.get(options, option, []))
    end
    Mnemonix.Store.Server.start_link implementation, store, server
  end

end
