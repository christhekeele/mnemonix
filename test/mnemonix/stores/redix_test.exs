defmodule Mnemonix.Stores.Redix.Test do
  use ExUnit.Case, async: true

  @moduletag :redis

  setup do
    on_exit fn ->
      File.rm_rf("dump.rdb")
      :ok
    end
  end

  doctest Mnemonix.Stores.Redix

end
