defmodule MnemonixTest do
  use ExUnit.Case, async: true
  
  doctest Mnemonix

  test "implements (almost) all functions in Map" do
    assert Map.__info__(:functions) -- Mnemonix.__info__(:functions) == [
      drop: 2,
      equal?: 2,
      from_struct: 1,
      keys: 1,
      merge: 2,
      merge: 3,
      size: 1,
      split: 2, # TODO
      take: 2, # TODO
      to_list: 1,
      values: 1,
    ]
  end
  
end