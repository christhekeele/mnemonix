defmodule Mnemonix.Test do
  use Mnemonix.Test.Case, async: true

  doctest Mnemonix

  test "implements (almost) all functions in Map" do
    missing = [
      # drop: 2,
      # equal?: 2,
      from_struct: 1,
      # keys: 1,
      merge: 2,
      merge: 3,
      # split: 2,
      # take: 2,
      # to_list: 1,
      # values: 1,
    ]
    missing = if :gt == System.version |> Version.parse! |> Version.compare(Version.parse!("1.4.0")) do
      Enum.sort missing ++ [size: 1]
    else; missing; end

    assert Map.__info__(:functions) -- Mnemonix.__info__(:functions) == missing
  end

end
