defmodule Mnemonix.Supervisor do

  use Supervisor

  @typedoc """
  Options used to start a store.
  """
  @type options :: [
    otp_app: atom,
    store: Mnemonix.Store.options,
    server: GenServer.opts,
  ]

  @typedoc """
  A two-tuple describing a store type and options to start it.
  """
  @type config :: {Mnemonix.Store.Behaviour.t, options}

  @moduledoc """
  A pre-rolled supervisor to complement store.
  """

  @doc """
  Creates and supervises a store for each entry in `config`.

  `options` are passed verbatim into `Supervisor.start_link/3`.

  `config` can be a single `t:Mnemonix.Supervisor.config/0` or a list of them.
  """
  @spec start_link(config | [config], Supervisor.options) :: Supervisor.on_start
  def start_link(config, options \\ []) do
    Supervisor.start_link(__MODULE__, config, options)
  end

  @doc false
  def init(config) do
    config
    |> List.wrap
    |> Enum.map(fn {impl, opts} ->
      Supervisor.Spec.worker(Mnemonix.Store.Server, [impl, opts], id: make_ref())
    end)
    |> Supervisor.Spec.supervise(strategy: :one_for_one)
  end

end
