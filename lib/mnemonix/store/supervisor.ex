defmodule Mnemonix.Store.Supervisor do

  alias Mnemonix.Store.Server.Spec

  def start_link(stores \\ []) do
    Supervisor.start_link(__MODULE__, stores)
  end

  def init(stores) do
    stores
    |> specs
    |> Enum.map(&Spec.worker/1)
    |> Supervisor.Spec.supervise(strategy: :one_for_one)
  end

  def specs(stores) do
    stores |> inspect |> IO.puts
    specs = stores
    |> coerce_specs([])
    |> :lists.reverse
    specs |> inspect |> IO.puts
    specs
  end

  defp coerce_specs([], specs), do: specs
  defp coerce_specs([spec = {_, %Spec{}} | rest], specs) do
    coerce_specs(rest, [spec | specs])
  end
  defp coerce_specs([{name, opts} | rest], specs) do
    coerce_specs(rest, [Spec.new({name, opts}) | specs])
  end
  defp coerce_specs([name | rest], specs) do
    coerce_specs([{name, Spec.default_opts()} | rest], specs)
  end

end
