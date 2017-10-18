defmodule Mnemonix.Builder.Bench do
  use Benchfella

  defmodule Store do
    use Mnemonix.Builder, singleton: true
  end

  setup_all do
    Application.load(:mnemonix)
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
