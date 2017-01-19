defmodule Mnemonix.DETS.Store.Test do
  use ExUnit.Case, async: true

  setup do
    on_exit fn ->
      :dets.close(Mnemonix.DETS.Store.Table)
      File.rm_rf("Elixir.Mnemonix.DETS.Store.Table")
      :ok
    end
  end

  doctest Mnemonix.DETS.Store

end
