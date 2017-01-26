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
  """

  use Mnemonix.Store.Behaviour, doc: false
  use Mnemonix.Store.Translator.Raw

  alias Mnemonix.Store

  @spec setup(Mnemonix.Store.options)
    :: {:ok, nil}
  def setup(_opts) do
    {:ok, nil}
  end

  @spec delete(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t}
  def delete(store = %Store{}, _key) do
    {:ok, store}
  end

  @spec fetch(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t, {:ok, Mnemonix.value}}
  def fetch(store = %Store{}, _key) do
    {:ok, store, {:ok, nil}}
  end

  @spec put(Mnemonix.Store.t, Mnemonix.key, Store.value)
    :: {:ok, Mnemonix.Store.t}
  def put(store = %Store{}, _key, _value) do
    {:ok, store}
  end
end
