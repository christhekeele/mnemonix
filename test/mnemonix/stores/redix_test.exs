defmodule Mnemonix.Stores.Redix.Test do
  use Mnemonix.Test.Case, async: true, artifacts: "dump.rdb"

  @moduletag :redis

  doctest Mnemonix.Stores.Redix

end
