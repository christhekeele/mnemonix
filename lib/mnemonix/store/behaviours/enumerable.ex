defmodule Mnemonix.Store.Behaviours.Enumerable do
  @moduledoc false

  alias Mnemonix.Store.Server

  use Mnemonix.Behaviour

####
# DERIVABLE
##

####
# Mnemonix.Store.Behaviours.Enumerable
##

  @callback enumerable?(Mnemonix.Store.t)
    :: Server.instruction(boolean)
  @doc """
  Returns `false`: this store does not support the functions in `Mnemonix.Features.Enumerable`.

  Invoking any of those functions on this store will raise a `Mnemonix.Features.Enumerable.Error`.
  """
  @spec enumerable?(Mnemonix.Store.t)
    :: Server.instruction(boolean)
  def enumerable?(store) do
    {:ok, store, false}
  end

  @callback to_enumerable(Mnemonix.Store.t)
    :: Server.instruction(Enumerable.t)
  @doc false
  @spec to_enumerable(Mnemonix.Store.t)
    :: Server.instruction(Enumerable.t)
  def to_enumerable(store) do
    {:raise, Mnemonix.Features.Enumerable.Error, [module: store.impl]}
  end

  @callback keys(Mnemonix.Store.t)
    :: Server.instruction([Mnemonix.key] | {:default, module})
  @doc false
  @spec keys(Mnemonix.Store.t)
    :: Server.instruction([Mnemonix.key] | {:default, module})
  def keys(store) do
    {:ok, store, {:default, store.impl}}
  end

  @callback to_list(Mnemonix.Store.t)
    :: Server.instruction([{Mnemonix.key, Mnemonix.value}] | {:default, module})
  @doc false
  @spec to_list(Mnemonix.Store.t)
    :: Server.instruction([{Mnemonix.key, Mnemonix.value}] | {:default, module})
  def to_list(store) do
    {:ok, store, {:default, store.impl}}
  end

  @callback values(Mnemonix.Store.t)
    :: Server.instruction([Mnemonix.key] | {:default, module})
  @doc false
  @spec values(Mnemonix.Store.t)
    :: Server.instruction([Mnemonix.key] | {:default, module})
  def values(store) do
    {:ok, store, {:default, store.impl}}
  end

####
# Enumerable Protocol
##

  @callback enumerable_count(Mnemonix.Store.t)
    :: Server.instruction(non_neg_integer | {:error, module})
  @doc false
  @spec enumerable_count(Mnemonix.Store.t)
    :: Server.instruction(non_neg_integer | {:error, module})
  def enumerable_count(store) do
    {:ok, store, {:error, store.impl}}
  end

  @callback enumerable_member?(Mnemonix.Store.t, {Mnemonix.key, Mnemonix.value})
    :: Server.instruction(boolean | {:error, module})
  @doc false
  @spec enumerable_member?(Mnemonix.Store.t, {Mnemonix.key, Mnemonix.value})
    :: Server.instruction(boolean | {:error, module})
  def enumerable_member?(store, {_key, _value}) do
    {:ok, store, {:error, store.impl}}
  end

  @callback enumerable_reduce(Mnemonix.Store.t, Enumerable.acc, Enumerable.reducer)
    :: Server.instruction(Enumerable.result | {:error, module})
  @doc false
  @spec enumerable_reduce(Mnemonix.Store.t, Enumerable.acc, Enumerable.reducer)
    :: Server.instruction(Enumerable.result | {:error, module})
  def enumerable_reduce(store, _acc, _reducer) do
    {:ok, store, {:error, store.impl}}
  end

####
# Collectable Protocol
##

  @callback collectable_into(Mnemonix.Store.t, Enumerable.t)
    :: Server.instruction(Enumerable.t | {:error, module})
  @doc false
  @spec collectable_into(Mnemonix.Store.t, Enumerable.t)
    :: Server.instruction(Enumerable.t | {:error, module})
  def collectable_into(store, _shape) do
    {:ok, store, {:error, store.impl}}
  end

end
