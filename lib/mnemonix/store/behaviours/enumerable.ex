defmodule Mnemonix.Store.Behaviours.Enumerable do
  @moduledoc false

  use Mnemonix.Behaviour

####
# DERIVABLE
##

####
# Mnemonix.Store.Behaviours.Enumerable
##

  @callback enumerable?(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception
  @doc """
  Returns `false`: this store does not support the functions in `Mnemonix.Features.Enumerable`.

  Invoking any of those functions on this store will raise a `Mnemonix.Features.Enumerable.Error`.
  """
  @spec enumerable?(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception
  def enumerable?(store) do
    {:ok, store, false}
  end

  @callback to_enumerable(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec to_enumerable(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t} | Mnemonix.Store.Behaviour.exception
  def to_enumerable(store) do
    {:raise, Mnemonix.Features.Enumerable.Error, [module: store.impl]}
  end

  @callback keys(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:default, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec keys(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:default, module}} | Mnemonix.Store.Behaviour.exception
  def keys(store) do
    {:ok, store, {:default, store.impl}}
  end

  @callback to_list(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [{Mnemonix.key, Mnemonix.value}] | {:default, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec to_list(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [{Mnemonix.key, Mnemonix.value}] | {:default, module}} | Mnemonix.Store.Behaviour.exception
  def to_list(store) do
    {:ok, store, {:default, store.impl}}
  end

  @callback values(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:default, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec values(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:default, module}} | Mnemonix.Store.Behaviour.exception
  def values(store) do
    {:ok, store, {:default, store.impl}}
  end

####
# Enumerable Protocol
##

  @callback enumerable_count(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, non_neg_integer | {:error, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec enumerable_count(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, non_neg_integer | {:error, module}} | Mnemonix.Store.Behaviour.exception
  def enumerable_count(store) do
    {:ok, store, {:error, store.impl}}
  end

  @callback enumerable_member?(Mnemonix.Store.t, {Mnemonix.key, Mnemonix.value})
    :: {:ok, Mnemonix.Store.t, boolean | {:error, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec enumerable_member?(Mnemonix.Store.t, {Mnemonix.key, Mnemonix.value})
    :: {:ok, Mnemonix.Store.t, boolean | {:error, module}} | Mnemonix.Store.Behaviour.exception
  def enumerable_member?(store, {_key, _value}) do
    {:ok, store, {:error, store.impl}}
  end

  @callback enumerable_reduce(Mnemonix.Store.t, Enumerable.acc, Enumerable.reducer)
    :: {:ok, Mnemonix.Store.t, Enumerable.result | {:error, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec enumerable_reduce(Mnemonix.Store.t, Enumerable.acc, Enumerable.reducer)
    :: {:ok, Mnemonix.Store.t, Enumerable.result | {:error, module}} | Mnemonix.Store.Behaviour.exception
  def enumerable_reduce(store, _acc, _reducer) do
    {:ok, store, {:error, store.impl}}
  end

####
# Collectable Protocol
##

  @callback collectable_into(Mnemonix.Store.t, Enumerable.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t | {:error, module}} | Mnemonix.Store.Behaviour.exception
  @doc false
  @spec collectable_into(Mnemonix.Store.t, Enumerable.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t | {:error, module}} | Mnemonix.Store.Behaviour.exception
  def collectable_into(store, _shape) do
    {:ok, store, {:error, store.impl}}
  end

end
