if Code.ensure_loaded?(Redix) do
  defmodule Mnemonix.Stores.Redix.Test do
    use Mnemonix.Test.Case, async: true, artifacts: "dump.rdb"

    @moduletag :redis

    setup_all do
      {:ok, conn} = Redix.start_link(
        host: Redis.TestHelpers.test_host(),
        port: Redis.TestHelpers.test_port(),
      )
      Redix.command conn, ["FLUSHDB"]
      :ok
    end

    doctest Mnemonix.Stores.Redix

  end
end
