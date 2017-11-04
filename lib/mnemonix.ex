defmodule Mnemonix do
  @moduledoc """
  Provides easy access to a store through a Map-like interface.

  Rather than a map, you can use the `t:GenServer.server/0` reference returned
  by `Mnemonix.Features.Supervision.start_link/2` to perform operations on Mnemonix stores.

  All functions defined in the `Mnemonix.Features` modules are available on the `Mnemonix` module:

  - `Mnemonix.Features.Map`
  - `Mnemonix.Features.Bump`
  - `Mnemonix.Features.Expiry`
  - `Mnemonix.Features.Enumerable`
  - `Mnemonix.Features.Supervision`

  ## Supervision Features

  `Mnemonix.Features.Supervision` provides the `start_link` implementations that enable all stores
  to fit into the `Mnemonix.Application` and `Mnemonix.Supervisor` tools out of the box.

  ## Map Features

  `Mnemonix.Features.Map` lets you manipulate a store just like a `Map`.

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

  These functions behave exactly like their `Map` counterparts. `Mnemonix`
  doesn't supply analogs for only a few Map functions:

  - `Map.from_struct/1`
  - `Map.merge/2`
  - `Map.merge/3`

  Map functions that traverse every entry in a store are handled a little differently, in the Enumerable feature below.

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
  functions keep parity with the `Map` API, but be warned: they are only implemented for a subset of
  stores, and may be very inefficient. Consult your store's specific documentation for more details.

  These `Map` equivalents will raise `Mnemonix.Features.Enumerable.Error` if your store doesn't
  support them:

  - `Mnemonix.Features.Enumerable.equal?/2`
  - `Mnemonix.Features.Enumerable.keys/1`
  - `Mnemonix.Features.Enumerable.to_list/1`
  - `Mnemonix.Features.Enumerable.values/1`

  Any store can be checked for enumerable support via `Mnemonix.enumerable?/1`.

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

  See `Mnemonix.Application` for more on how the `options` are consumed.
  """
  @spec start(Application.start_type, Mnemonix.Application.options)
    :: {:ok, store} | {:error, reason :: term}
  def start(_type, [default]) do
    Mnemonix.Application.start_link(default)
  end

  use Mnemonix.Builder

  @doc """
  Starts a new empty in-memory store.

  ## Examples

      iex> store = Mnemonix.new
      iex> Mnemonix.get(store, :a)
      nil
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec new() :: store
  def new() do
    do_new Map.new
  end

  @doc """
  Starts a new in-memory store using `enumerable` for initial data.

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
  Starts a new store applying a `transformation` to `enumerable` for initial data.

  Duplicated keys are removed; the last mentioned one prevails.

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
    {impl, opts} = Mnemonix.Application.default
    opts = if Keyword.get(opts, :store), do: opts, else: Keyword.put(opts, :store, [])
    opts = Kernel.put_in(opts, [:store, :initial], map)
    with {:ok, store} <- start_link(impl, opts), do: store
  end

end
