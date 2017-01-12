defmodule Mnemonix do
  @moduledoc """
  Easy access to `Mnemonix.Store` servers with a Map-like interface.

  Rather than a map, you can use the `t:GenServer.server/0` reference returned
  by `Mnemonix.Store.start_link/2` to perform operations on Mnemonix stores.

  ## Map Operations

  You make calls to `Mnemonix.Store` servers as if they were Maps.

  Rather than a map, you use the `t:GenServer.server/0` reference returned
  by `Mnemonix.Store.start_link/2` to perform operations on Mnemonix stores.

  The `new/0`, `new/1`, and `new/3` functions start links to a
  `Mnemonix.Map.Store` (mimicking `Map.new`) to make it easy to play with the
  Mnemonix interface:

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.get(store, :foo)
      nil
      iex> Mnemonix.get(store, :fizz)
      1
      iex> Mnemonix.put_new(store, :foo, "bar")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.put_new(store, :foo, "baz")
      iex> Mnemonix.get(store, :foo)
      "bar"
      iex> Mnemonix.put(store, :foo, "baz")
      iex> Mnemonix.get(store, :foo)
      "baz"
      iex> Mnemonix.get(store, :fizz)
      1
      iex> Mnemonix.get_and_update(store, :fizz, &({&1, &1 * 2}))
      iex> Mnemonix.get_and_update(store, :fizz, &({&1, &1 * 2}))
      iex> Mnemonix.get(store, :fizz)
      4

  These functions behave exactly like their Map counterparts. However, `Mnemonix`
  doesn't supply analogs for functions that assume a store can be exhaustively
  iterated or fit into a specific shape:

  - `equal?(Map.t, Map.t) :: boolean`
  - `from_struct(Struct.t) :: Map.t`
  - `keys(Map.t) :: [keys]`
  - `merge(Map.t, Map.t) :: Map.t`
  - `merge(Map.t, Map.t, callback) :: Map.t`
  - `split(Map.t, keys) :: Map.t`
  - `take(Map.t, keys) :: Map.t`
  - `to_list(Map.t) :: Map.t`
  - `values(Map.t) :: [values]`

  ## Expiry Operations

  Mnemonix lets you set entries to expire after a given time-to-live on any store.

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.expire(store, :fizz, 100)
      iex> :timer.sleep(1000)
      iex> Mnemonix.get(store, :fizz)
      nil

  ## Bump Operations

  Mnemonix lets you perform increment/decrement operations on any store.

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.increment(store, :fizz)
      iex> Mnemonix.get(store, :fizz)
      2
      iex> Mnemonix.decrement(store, :fizz)
      iex> Mnemonix.get(store, :fizz)
      1

  """

  use Mnemonix.Store.API

end
