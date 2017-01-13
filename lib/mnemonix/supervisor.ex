defmodule Mnemonix.Supervisor do

  def start_link(stores \\ []) do
    Supervisor.start_link(__MODULE__, stores)
  end

  def init(stores) do
    stores
    |> specs
    |> Enum.map(&Mnemonix.Store.Spec.worker/1)
    |> Supervisor.Spec.supervise(strategy: :one_for_one)
  end

  def specs(stores) do
    stores
    |> coerce_specs([])
    |> :lists.reverse
  end

  defp coerce_specs([], specs), do: specs
  defp coerce_specs([spec = %Mnemonix.Store.Spec{} | rest], specs) do
    coerce_specs(rest, [spec | specs])
  end
  defp coerce_specs([store | rest], specs) do
    coerce_specs(rest, [Mnemonix.Store.Spec.new(store) | specs])
  end

end
