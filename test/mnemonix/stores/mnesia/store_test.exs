defmodule Mnemonix.Mnesia.Store.Test do
  use ExUnit.Case, async: true

  setup do
    on_exit fn ->
      File.rm_rf("Mnesia.nonode@nohost")
      :ok
    end
  end

  # Intermittent failures:
  # test doc at Mnemonix.Mnesia.Store.start_link/1 (2) (Mnemonix.Mnesia.StoreTest)
  #    test/mnemonix/stores/mnesia/store_test.exs:11
  #    ** (EXIT from #PID<0.xxx.0>) {:node_not_running, :nonode@nohost}
  # doctest Mnemonix.Mnesia.Store

end
