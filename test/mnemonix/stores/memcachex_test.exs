if Code.ensure_loaded?(Memcache) do
  defmodule Mnemonix.Stores.Memcachex.Test do
    use Mnemonix.Test.Case, async: true

    @moduletag :memcached

    doctest Mnemonix.Stores.Memcachex

  end
end
