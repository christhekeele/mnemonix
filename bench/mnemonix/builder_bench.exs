defmodule Mnemonix.Builder.Bench do
  use Benchfella

  defmodule Store do
    use Mnemonix.Builder

    def start_link do
      Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, server: [name: __MODULE__])
    end
  end

  setup_all do
    Store.start_link
  end

  teardown_all store do
    GenServer.stop store
  end

  bench "core operations" do
    {:ok, "b"} = Store
    |> Mnemonix.put("a", "b")
    |> Mnemonix.fetch("a")
    Mnemonix.delete(Store, "a")
  end

  bench "intense core operations" do
    for _ <- 1..1_000_000 do
      {:ok, "b"} = Store
      |> Mnemonix.put("a", "b")
      |> Mnemonix.fetch("a")
      Mnemonix.delete(Store, "a")
    end
  end
end
