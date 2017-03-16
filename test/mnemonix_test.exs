defmodule Mnemonix.Test do
  use Mnemonix.Test.Case, async: true

  doctest Mnemonix

  test "implements (almost) all functions in Map" do
    exceptions = [
      from_struct: 1,
      merge: 2,
      merge: 3,
      size: 1,
    ]

    assert Map.__info__(:functions) -- Mnemonix.__info__(:functions) == exceptions
  end

end
