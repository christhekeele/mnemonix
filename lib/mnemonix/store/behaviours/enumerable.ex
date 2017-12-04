defmodule Mnemonix.Store.Behaviours.Enumerable do
  @moduledoc false

  alias Mnemonix.Store

  use Mnemonix.Behaviour

  ####
  # DERIVABLE
  ##

  ####
  # Mnemonix.Store.Behaviours.Enumerable
  ##

  @callback enumerable?(Store.t()) :: Store.Server.instruction(boolean)
  @doc """
  Returns `false`: this store does not support the functions in `Mnemonix.Features.Enumerable`.

  Invoking any of those functions on this store will raise a `Mnemonix.Features.Enumerable.Error`.
  """
  @spec enumerable?(Store.t()) :: Store.Server.instruction(boolean)
  def enumerable?(store) do
    {:ok, store, false}
  end

  @callback to_enumerable(Store.t()) :: Store.Server.instruction([Mnemonix.pair()])
  @doc false
  @spec to_enumerable(Store.t()) :: Store.Server.instruction([Mnemonix.pair()])
  def to_enumerable(store) do
    {:raise, store, Mnemonix.Features.Enumerable.Error, [module: store.impl]}
  end

  @callback keys(Store.t()) :: Store.Server.instruction([Mnemonix.key()] | {:default, module})
  @doc false
  @spec keys(Store.t()) :: Store.Server.instruction([Mnemonix.key()] | {:default, module})
  def keys(store) do
    {:ok, store, {:default, store.impl}}
  end

  @callback to_list(Store.t()) :: Store.Server.instruction([Mnemonix.pair()] | {:default, module})
  @doc false
  @spec to_list(Store.t()) :: Store.Server.instruction([Mnemonix.pair()] | {:default, module})
  def to_list(store) do
    {:ok, store, {:default, store.impl}}
  end

  @callback values(Store.t()) :: Store.Server.instruction([Mnemonix.key()] | {:default, module})
  @doc false
  @spec values(Store.t()) :: Store.Server.instruction([Mnemonix.key()] | {:default, module})
  def values(store) do
    {:ok, store, {:default, store.impl}}
  end

  ####
  # Enumerable Protocol
  ##

  @callback enumerable_count(Store.t()) ::
              Store.Server.instruction(non_neg_integer | {:error, module})
  @doc false
  @spec enumerable_count(Store.t()) ::
          Store.Server.instruction(non_neg_integer | {:error, module})
  def enumerable_count(store) do
    {:ok, store, {:error, store.impl}}
  end

  @callback enumerable_member?(Store.t(), Mnemonix.pair() | term) ::
              Store.Server.instruction(boolean | {:error, module})
  @doc false
  @spec enumerable_member?(Store.t(), Mnemonix.pair() | term) ::
          Store.Server.instruction(boolean | {:error, module})
  def enumerable_member?(store, _maybe_pair) do
    {:ok, store, {:error, store.impl}}
  end

  @callback enumerable_reduce(Store.t(), Enumerable.acc(), Enumerable.reducer()) ::
              Store.Server.instruction(Enumerable.result() | {:error, module})
  @doc false
  @spec enumerable_reduce(Store.t(), Enumerable.acc(), Enumerable.reducer()) ::
          Store.Server.instruction(Enumerable.result() | {:error, module})
  def enumerable_reduce(store, _acc, _reducer) do
    {:ok, store, {:error, store.impl}}
  end

  ####
  # Collectable Protocol
  ##

  @callback collectable_into(Store.t(), [Mnemonix.pair()]) ::
              Store.Server.instruction([Mnemonix.pair()] | {:error, module})
  @doc false
  @spec collectable_into(Store.t(), [Mnemonix.pair()]) ::
          Store.Server.instruction([Mnemonix.pair()] | {:error, module})
  def collectable_into(store, _shape) do
    {:ok, store, {:error, store.impl}}
  end
end
