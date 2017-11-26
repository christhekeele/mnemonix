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

  alias Mnemonix.Store

  use Store.Behaviour
  use Store.Translator.Raw

####
# Mnemonix.Store.Behaviours.Core
##

  @doc """
  Skips setup since this store does nothing.

  Ignores all `opts`.
  """
  @impl Store.Behaviours.Core
  @spec setup(Store.options)
    :: {:ok, nil}
  def setup(_opts) do
    {:ok, nil}
  end

####
# Mnemonix.Store.Behaviours.Map
##

  @impl Store.Behaviours.Map
  @spec delete(Store.t, Mnemonix.key)
    :: {:ok, Store.t}
  def delete(store = %Store{}, _key) do
    {:ok, store}
  end

  @impl Store.Behaviours.Map
  @spec fetch(Store.t, Mnemonix.key)
    :: {:ok, Store.t, {:ok, Mnemonix.value}}
  def fetch(store = %Store{}, _key) do
    {:ok, store, {:ok, nil}}
  end

  @impl Store.Behaviours.Map
  @spec put(Store.t, Mnemonix.key, Mnemonix.value)
    :: {:ok, Store.t}
  def put(store = %Store{}, _key, _value) do
    {:ok, store}
  end

####
# Mnemonix.Store.Behaviours.Enumerable
##

  @doc """
  Returns `true`: this store supports the functions in `Mnemonix.Features.Enumerable`.
  """
  @impl Store.Behaviours.Enumerable
  @spec enumerable?(Store.t)
    :: {:ok, Store.t, boolean} | Store.Behaviour.exception
  def enumerable?(store) do
    {:ok, store, true}
  end

  @impl Store.Behaviours.Enumerable
  @spec to_enumerable(Store.t)
    :: {:ok, Store.t, Enumerable.t} | Store.Behaviour.exception
  def to_enumerable(store = %Store{}) do
    {:ok, store, []}
  end

end
