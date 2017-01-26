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

  use Mnemonix.Store.Behaviour

  alias Mnemonix.Store

  @spec setup(Mnemonix.Store.options)
    :: {:ok, nil}
  def setup(_opts) do
    {:ok, nil}
  end

  @doc false
  @spec serialize_key(Mnemonix.key, Mnemonix.Store.t)
    :: serialized_key :: term | no_return
  def serialize_key(key, _store) do
    key
  end

  @doc false
  @spec serialize_value(Mnemonix.value, Mnemonix.Store.t)
    :: serialized_value :: term | no_return
  def serialize_value(value, _store) do
    value
  end

  @doc false
  @spec deserialize_key(serialized_key :: term, Mnemonix.Store.t)
    :: Mnemonix.key :: term | no_return
  def deserialize_key(serialized_key, _store) do
    serialized_key
  end

  @doc false
  @spec deserialize_value(serialized_value :: term, Mnemonix.Store.t)
    :: Mnemonix.value :: term | no_return
  def deserialize_value(serialized_value, _store) do
    serialized_value
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
