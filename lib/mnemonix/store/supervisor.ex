defmodule Mnemonix.Store.Supervisor do

  use Supervisor

  alias Mnemonix.Store.Server

  @moduledoc """
  A pre-rolled supervisor to complement `Mnemonix.Store.Server`.
  """

  # alias Mnemonix.Store.Server.Spec

  @doc """
  Creates and supervises a `Mnemonix.Store.Server` for each entry in `config`.

  `options` are passed verbatim into `Supervisor.start_link/3`.

  `config` can be a single `t:Mnemonix.Store.Server.config/0` or a list of them.
  """
  @spec start_link(Server.config | [Server.config], Supervisor.options) :: Supervisor.on_start
  def start_link(config, options \\ []) do
    Supervisor.start_link(__MODULE__, config, options)
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
