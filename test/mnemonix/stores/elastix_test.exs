if Code.ensure_loaded?(Elastix) do
  defmodule Mnemonix.Stores.Elastix.Test do
    use Mnemonix.Test.Case, async: true

    @moduletag :elastic_search

    doctest Mnemonix.Stores.Elastix

  end
end
