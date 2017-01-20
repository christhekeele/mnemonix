defmodule Mnemonix do
  @moduledoc """
  Provides easy access to a `Mnemonix.Store.Server` through a Map-like interface.

  Rather than a map, you can use the `t:GenServer.server/0` reference returned
  by `Mnemonix.Store.Server.start_link/2` to perform operations on Mnemonix stores.

  All functions defined in the `Mnemonix.Features` modules are available on the `Mnemonix` module:

  - `Mnemonix.Features.Map`
  - `Mnemonix.Features.Bump`
  - `Mnemonix.Features.Expiry`

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
  doesn't supply analogs for functions that assume a store can be exhaustively
  iterated or fit into a specific shape:

  - `Map.equal?/2`
  - `Map.from_struct/1`
  - `Map.keys/1`
  - `Map.merge/2`
  - `Map.merge/3`
  - `Map.split/2`
  - `Map.take/2`
  - `Map.to_list/1`
  - `Map.values/1`

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
  Starts the `:mnemonix` application, supervising stores declared in your application configuration.

  Mnemonix can manage your stores for you. To do so, it looks in your config files for named stores:

  ```elixir
  config :mnemonix, stores: [:foo, :bar]
  ```

  For all stores so listed, it will check for store-specific configuration:

  ```elixir
  config :mnemonix, :foo, {Memonix.ETS.Store, [
    store: [table: :my_ets_table],
    server: []
  ]}
  ```

  If no configuration is found, it will use the `default` configuration provided to the application.
  Applications started through mix refer to `Mnemonix.Store.Spec.default/0` to determine this
  default, which currently uses `Mnemonix.Stores.Map` to create your configured stores.

  The name of the store in your config will be the reference you pass to `Mnemonix` to interact with it.

  Given the config above, `:foo` would refer to an ETS-backed store,
  and `:bar` to a default Map-backed store,
  both available to you at boot time without writing a line of code.

  ```elixir
  Mnemonix.put(:foo, :a, :b)
  Mnemonix.get(:foo, :a)
  #=> :b

  Mnemonix.put(:bar, :a, :b)
  Mnemonix.get(:bar, :a)
  #=> :b
  ```
  """
  @spec start(Application.start_type, opts :: term) ::
    {:ok, store} | {:error, reason :: term}
  def start(_type, [default]) do
    :mnemonix
    |> Application.get_env(:stores, [])
    |> Enum.map(fn name ->
      :mnemonix
      |> Application.get_env(name, default)
      |> start_defaults(name)
    end)
    |> Mnemonix.Store.Supervisor.start_link
  end

  defp start_defaults({module, opts}, name) do
    {module, opts
      |> Keyword.put(:otp_app, :mnemonix)
      |> Keyword.put_new(:server, [])
      |> Kernel.put_in([:server, :name], name)
    }
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
