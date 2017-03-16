defmodule Mnemonix do
  @moduledoc """
  Provides easy access to a `Mnemonix.Store.Server` through a Map-like interface.

  Rather than a map, you can use the `t:GenServer.server/0` reference returned
  by `Mnemonix.Store.Server.start_link/2` to perform operations on Mnemonix stores.

  All functions defined in the `Mnemonix.Features` modules are available on the `Mnemonix` module:

  - `Mnemonix.Features.Map`
  - `Mnemonix.Features.Bump`
  - `Mnemonix.Features.Expiry`
  - `Mnemonix.Features.Enumerable`

  ## Map Features

  `Mnemonix.Features.Map` lets you manipulate a `Mnemonix.Store.Server` just like a `Map`.

  The `new/0`, `new/1`, and `new/2` functions start links to a
  `Mnemonix.Stores.Map` (mimicking `Map.new`) and make it easy to play with the
  Mnemonix functions:

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

  These functions behave exactly like their `Map` counterparts. However, `Mnemonix`
  doesn't supply analogs for functions that assume a store can be fit into a specific shape:

  - `Map.from_struct/1`
  - `Map.merge/2`
  - `Map.merge/3`

  Functions that exhaustively iterate over a store's contents live are implemented differently, see below.

  ## Bump Features

  `Mnemonix.Features.Bump` lets you perform increment/decrement operations on any store.

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.increment(store, :fizz)
      iex> Mnemonix.get(store, :fizz)
      2
      iex> Mnemonix.decrement(store, :fizz)
      iex> Mnemonix.get(store, :fizz)
      1

  ## Expiry Features

  `Mnemonix.Features.Expiry` lets you set entries to expire after a given time-to-live on any store.

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.expire(store, :fizz, 100)
      iex> :timer.sleep(1000)
      iex> Mnemonix.get(store, :fizz)
      nil

  ## Enumerable Features

  `Mnemonix.Features.Enumerable` enables functions that try to iterate over a store's contents. These
  functions are to keep as much parity with the `Map` API as possible, but be warned: they are only
  implemented for a subset of stores, and may be very inefficient. Consult your store's specific
  documentation for more details.

  These `Map` equivalents will raise `Mnemonix.Features.Enumerable.Error` if your store doesn't
  support them:

  - `Mnemonix.equal?/2`
  - `Mnemonix.keys/1`
  - `Mnemonix.to_list/1`
  - `Mnemonix.values/1`

  Any store can be checked for enumerability support via `Mnemonix.enumerable?/1`.

  """

  @typedoc """
  Keys allowed in Mnemonix entries.
  """
  @type key :: term

  @typedoc """
  Values allowed in Mnemonix entries.
  """
  @type value :: term

  @typedoc """
  Values representing a store that Mnemonix functions can operate on.
  """
  @type store :: pid | GenServer.name

  use Application

  @doc """
  Starts the `:mnemonix` application.

  Finds stores in your application configuration and brings them up when your app starts with the
  specified start `type`.

  See `Mnemonix.Application` for more on how the `opts` are consumed.
  """
  @spec start(Application.start_type, [Mnemonix.Store.Server.config])
    :: {:ok, store} | {:error, reason :: term}
  def start(_type, _opts = [default]) do
    Mnemonix.Application.start_link(default)
  end

  @doc """
  Starts a new empty `Mnemonix.Stores.Map`-powered `Mnemonix.Store.Server`.

  ## Examples

      iex> store = Mnemonix.new
      iex> Mnemonix.get(store, :a)
      nil
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec new() :: store
  def new() do
    with {:ok, store} <- Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map) do
      store
    end
  end

  @doc """
  Starts a new `Mnemonix.Stores.Map`-powered `Mnemonix.Store.Server` using `enumerable` for initial data.

  Duplicated keys in the `enumerable` are removed; the last mentioned one prevails.

  ## Examples

      iex> store = Mnemonix.new(a: 1)
      iex> Mnemonix.get(store, :a)
      1
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec new(Enum.t) :: store
  def new(enumerable) do
    do_new Map.new(enumerable)
  end

  @doc """
  Starts a new `Mnemonix.Stores.Map`-powered `Mnemonix.Store.Server` applying a `transformation` to `enumerable` for initial data.

  Duplicated keys are removed; the latest one prevails.

  ## Examples

      iex> store = Mnemonix.new(%{"A" => 0}, fn {key, value} ->
      ...>  { String.downcase(key), value + 1 }
      ...> end )
      iex> Mnemonix.get(store, "a")
      1
      iex> Mnemonix.get(store, "A")
      nil
  """
  @spec new(Enum.t, (term -> {key, value})) :: store
  def new(enumerable, transform) do
    do_new Map.new(enumerable, transform)
  end

  defp do_new(map) do
    options = [store: [initial: map]]
    with {:ok, store} <- Mnemonix.Store.Server.start_link(Mnemonix.Stores.Map, options), do: store
  end

  use Mnemonix.Builder

end
