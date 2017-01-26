defmodule Mnemonix.Stores.Mnesia.Test do
  use ExUnit.Case, async: true, artifacts: "Mnesia.nonode@nohost"

  @moduletag :filesystem

  setup do
    :mnesia.create_schema([node()])
    :mnesia.start()
    on_exit fn ->
      File.rm_rf("Mnesia.nonode@nohost")
      :ok
    end
  end

  doctest Mnemonix.Stores.Mnesia

end
