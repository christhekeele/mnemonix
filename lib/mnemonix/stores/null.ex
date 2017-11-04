defmodule Mnemonix.Stores.Null do
  @moduledoc """
  A `Mnemonix.Store` that does literally nothing.

      iex> {:ok, store} = Mnemonix.Stores.Null.start_link
      iex> Mnemonix.put(store, "foo", "bar")
      iex> Mnemonix.get(store, "foo")
      nil
      iex> Mnemonix.delete(store, "foo")
      iex> Mnemonix.get(store, "foo")
      nil

  This store supports the functions in `Mnemonix.Features.Enumerable`.
  """

  use Mnemonix.Store.Behaviour
  use Mnemonix.Store.Translator.Raw

  alias Mnemonix.Store

####
# Mnemonix.Store.Behaviours.Core
##

  # Overrides documentation for start_links to demonstrate their null behaviour instead.

  @doc """
  Starts a new store using the `Mnemonix.Stores.Null` module with `options`.

  The `options` are the same as described in `Mnemonix.Features.Supervision.start_link/2`.
  The `:store` options are used in `config/1` to start the store;
  the `:server` options are passed directly to `GenServer.start_link/2`.

  The returned `t:GenServer.server/0` reference can be used as the primary
  argument to the `Mnemonix` API.

  ## Examples

      iex> {:ok, store} = Mnemonix.Stores.Null.start_link()
      iex> Mnemonix.put(store, "foo", "bar")
      iex> Mnemonix.get(store, "foo")
      nil

      iex> {:ok, _store} = Mnemonix.Stores.Null.start_link(server: [name: My.Mnemonix.Stores.Null])
      iex> Mnemonix.put(My.Mnemonix.Stores.Null, "foo", "bar")
      iex> Mnemonix.get(My.Mnemonix.Stores.Null, "foo")
      nil
  """
  @impl Mnemonix.Store.Behaviours.Core
  @spec start_link()                            :: GenServer.on_start
  @spec start_link(Mnemonix.Supervisor.options) :: GenServer.on_start
  def start_link(options \\ [])
  def start_link(options), do: super(options)

  ####
  # Mnemonix.Store.Behaviours.Core
  ##

  @doc """
  Starts a new store using `Mnemonix.Stores.Null` with `store` and `server` options.

  The options are the same as described in `Mnemonix.start_link/2`.
  The `store` options are used in `config/1` to start the store;
  the `server` options are passed directly to `GenServer.start_link/2`.

  The returned `t:GenServer.server/0` reference can be used as the primary
  argument to the `Mnemonix` API.

  ## Examples

      iex> {:ok, store} = Mnemonix.Stores.Null.start_link([], [])
      iex> Mnemonix.put(store, "foo", "bar")
      iex> Mnemonix.get(store, "foo")
      nil

      iex> {:ok, _store} = Mnemonix.Stores.Null.start_link([], [name: My.Mnemonix.Stores.Null])
      iex> Mnemonix.put(My.Mnemonix.Stores.Null, "foo", "bar")
      iex> Mnemonix.get(My.Mnemonix.Stores.Null, "foo")
      nil
  """
  @impl Mnemonix.Store.Behaviours.Core
  @spec start_link(Mnemonix.Supervisor.options, GenServer.options) :: GenServer.on_start
  def start_link(store, server), do: super(store, server)

####
# Mnemonix.Store.Behaviours.Core
##

  @doc """
  Skips setup since this store does nothing.

  Ignores all `opts`.
  """
  @impl Mnemonix.Store.Behaviours.Core
  @spec setup(Mnemonix.Store.options)
    :: {:ok, nil}
  def setup(_opts) do
    {:ok, nil}
  end

####
# Mnemonix.Store.Behaviours.Map
##

  @impl Mnemonix.Store.Behaviours.Map
  @spec delete(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t}
  def delete(store = %Store{}, _key) do
    {:ok, store}
  end

  @impl Mnemonix.Store.Behaviours.Map
  @spec fetch(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, {:ok, Mnemonix.value}}
  def fetch(store = %Store{}, _key) do
    {:ok, store, {:ok, nil}}
  end

  @impl Mnemonix.Store.Behaviours.Map
  @spec put(Mnemonix.Store.t, Mnemonix.key, Store.value)
    :: {:ok, Mnemonix.Store.t}
  def put(store = %Store{}, _key, _value) do
    {:ok, store}
  end

####
# Mnemonix.Store.Behaviours.Enumerable
##

  @impl Mnemonix.Store.Behaviours.Enumerable
  @spec enumerable?(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception
  def enumerable?(store) do
    {:ok, store, true}
  end

  @impl Mnemonix.Store.Behaviours.Enumerable
  @spec to_enumerable(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t} | Mnemonix.Store.Behaviour.exception
  def to_enumerable(store = %Store{}) do
    {:ok, store, []}
  end

end
