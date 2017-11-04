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
