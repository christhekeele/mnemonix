defmodule Mnemonix do
  @moduledoc """
  Provides easy access to a `Mnemonix.Store.Server` through a Map-like interface.

  Rather than a map, you can use the `t:GenServer.server/0` reference returned
  by `Mnemonix.Store.Server.start_link/2` to perform operations on Mnemonix stores.

  All functions defined in the `Mnemonix.Features` modules are available on the `Mnemonix` module:

  - `Mnemonix.Features.Core`
  - `Mnemonix.Features.Map`
  - `Mnemonix.Features.Bump`
  - `Mnemonix.Features.Expiry`

  ## Map Features

  Most of the functions available in the `Map` module are implemented through `Mnemonix.Features.Map`.

  The `new/0`, `new/1`, and `new/3` functions start links to a
  `Mnemonix.Stores.Map` (mimicking `Map.new`) and make it easy to play with the
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

  ## Expiry Features

  Mnemonix lets you set entries to expire after a given time-to-live on any store.

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.expire(store, :fizz, 100)
      iex> :timer.sleep(1000)
      iex> Mnemonix.get(store, :fizz)
      nil

  ## Bump Features

  Mnemonix lets you perform increment/decrement operations on any store.

      iex> store = Mnemonix.new(fizz: 1)
      iex> Mnemonix.increment(store, :fizz)
      iex> Mnemonix.get(store, :fizz)
      2
      iex> Mnemonix.decrement(store, :fizz)
      iex> Mnemonix.get(store, :fizz)
      1

  """

  use Application

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

  @doc """
  Starts the Mnemonix Application, supervising the configured `stores`.

  Looks in the application configuration for any stores:

  ```elixir
  config :mnemonix, stores: [:foo, :bar]
  ```

  For all stores listed, will check for store-specific configuration:

  ```elixir
  config :mnemonix, :foo, [
    impl: Memonix.ETS.Store,
    opts: [
      table: :my_ets_table
    ]
  ]
  ```

  If no configuration is found, it will use the value of `default`, which by default is provided by
  `Mnemonix.Store.Spec.default/0`.

  Finally, it will launch all stores in new `Mnemonix.Store.Server` servers,
  each registered by the name used in the configuration,
  all supervised by a simple-one-for-one `Mnemonix.Store.Supervisor`.
  """
  @spec start(Application.start_type, opts :: term) ::
    {:ok, store} | {:error, reason :: term}
  def start(_type, opts) do
    :mnemonix
    |> Application.get_env(:stores, [])
    |> Mnemonix.Store.Supervisor.start_link(opts)
  end

  @doc """
  Starts a new `Mnemonix.Stores.Map server` with an empty map.

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
  Starts a new `Mnemonix.Stores.Map` server from the `enumerable`.

  Duplicated keys are removed; the latest one prevails.

  ## Examples

      iex> store = Mnemonix.new(a: 1)
      iex> Mnemonix.get(store, :a)
      1
      iex> Mnemonix.get(store, :b)
      nil
  """
  @spec new(Enum.t) :: store
  def new(enumerable) do
    init = {Mnemonix.Stores.Map, [initial: Map.new(enumerable)]}
    with {:ok, store} <- Mnemonix.Store.Server.start_link(init), do: store
  end

  @doc """
  Starts a new `Mnemonix.Stores.Map` server from the `enumerable` via
  the `transformation` function.

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
    init = {Mnemonix.Stores.Map, [initial: Map.new(enumerable, transform)]}
    with {:ok, store} <- Mnemonix.Store.Server.start_link(init), do: store
  end

  use Mnemonix.Builder

end
