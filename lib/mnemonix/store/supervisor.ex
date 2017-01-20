defmodule Mnemonix.Store.Supervisor do

  use Supervisor

  alias Mnemonix.Store.Server

  @moduledoc """
  A pre-rolled supervisor to complement `Mnemonix.Store.Server`.
  """

  # alias Mnemonix.Store.Server.Spec

  @doc """
  Creates and supervises a `Mnemonix.Store.Server` from each entry in `config`.

  `options` are passed verbatim into `Supervisor.start_link/3`.

  `config` is expected to be a list of lists, where item is a worker specification for a
  `Mnemonix.Store.Server`. A specification should contain:

  - an `impl` - a `Mnemonix.Stores` module to use in the worker
  - some `opts` - a value to provide to the worker store module's `setup/1` function
  - a `name` - an optional name for the worker to register itself under so you can access it later

  The format of this specification is very fluid:

  - `{otp_app, name}`

    Looks in the application configuration of `otp_app` for configuration options under `name` to use.

  - `{name, [impl: impl, opts: opts]}`

    Allows you to furnish a `Keyword` list of `Keyword` lists to build workers from.

  - `[impl: impl, opts: opts, name: name]`

    A simple `Keyword` list of the required data.
  """
  @spec start_link(Server.config | [Server.config], Supervisor.options) :: Supervisor.on_start
  def start_link(config, opts \\ []) do
    Supervisor.start_link(__MODULE__, config, opts)
  end

  @doc false
  def init(config) do
    config
    |> List.wrap
    |> Enum.map(fn {impl, opts} ->
      Supervisor.Spec.worker(Server, [impl, opts], id: make_ref())
    end)
    |> Supervisor.Spec.supervise(strategy: :one_for_one)
  end

end
