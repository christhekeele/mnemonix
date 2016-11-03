defmodule Mnemonix.Mnesia.StoreTest do
  use ExUnit.Case, async: true

  setup do
    on_exit fn ->
      File.rm_rf("Mnesia.nonode@nohost")
      :ok
    end
  end

  doctest Mnemonix.Mnesia.Store

end
