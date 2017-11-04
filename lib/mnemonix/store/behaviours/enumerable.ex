defmodule Mnemonix.Store.Behaviours.Enumerable do
  @moduledoc false

####
# Mnemonix.Store.Behaviours.Enumerable
##

  @callback enumerable?(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception

  @callback to_enumerable(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t} | Mnemonix.Store.Behaviour.exception

  @callback keys(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @callback to_list(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [{Mnemonix.key, Mnemonix.value}] | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @callback values(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:error, module}} | Mnemonix.Store.Behaviour.exception

####
# Enumerable Protocol
##

  @callback enumerable_count(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, non_neg_integer | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @callback enumerable_member?(Mnemonix.Store.t, {Mnemonix.key, Mnemonix.value})
    :: {:ok, Mnemonix.Store.t, boolean | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @callback enumerable_reduce(Mnemonix.Store.t, Enumerable.acc, Enumerable.reducer)
    :: {:ok, Mnemonix.Store.t, Enumerable.result} | Mnemonix.Store.Behaviour.exception

####
# Collectable Protocol
##

  @callback collectable_into(Mnemonix.Store.t, Enumerable.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour unquote __MODULE__

    ####
    # Mnemonix.Store.Behaviours.Enumerable
    ##

      @impl unquote __MODULE__
      def enumerable?(store) do
        {:ok, store, false}
      end

      @impl unquote __MODULE__
      def to_enumerable(_store) do
        {:raise, Mnemonix.Features.Enumerable.Error, [module: __MODULE__]}
      end

      @impl unquote __MODULE__
      def keys(store) do
        {:ok, store, {:default, __MODULE__}}
      end

      @impl unquote __MODULE__
      def to_list(store) do
        {:ok, store, {:default, __MODULE__}}
      end

      @impl unquote __MODULE__
      def values(store) do
        {:ok, store, {:default, __MODULE__}}
      end

    ####
    # Enumerable Protocol
    ##

      @impl unquote __MODULE__
      def enumerable_count(store) do
        {:ok, store, {:error, __MODULE__}}
      end

      @impl unquote __MODULE__
      def enumerable_member?(store, {_key, _value}) do
        {:ok, store, {:error, __MODULE__}}
      end

      @impl unquote __MODULE__
      def enumerable_reduce(store, _acc, _reducer) do
        {:ok, store, {:error, __MODULE__}}
      end

    ####
    # Collectable Protocol
    ##

      @impl unquote __MODULE__
      def collectable_into(store, _shape) do
        {:ok, store, {:error, __MODULE__}}
      end

    end
  end

end
