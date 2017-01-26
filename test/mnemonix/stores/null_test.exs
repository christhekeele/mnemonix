defmodule Mnemonix.Stores.Null.Test do
  use ExUnit.Case, async: true

  # doctest Mnemonix.Stores.Null

  test "put/get/delete" do
    {:ok, store} = Mnemonix.Stores.Null.start_link
    Mnemonix.put(store, "foo", "bar")
    assert Mnemonix.get(store, "foo") == nil

    Mnemonix.delete(store, "foo")
    assert Mnemonix.get(store, "foo") == nil
  end
end
