defmodule Mnemonix.Store.Behaviours.Enumerable do
  @moduledoc false

  ####
  # Mnemonix.Store.Behaviours.Enumerable
  ##

  @optional_callbacks enumerable?: 1
  @callback enumerable?(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, boolean} | Mnemonix.Store.Behaviour.exception

  @optional_callbacks to_enumerable: 1
  @callback to_enumerable(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t} | Mnemonix.Store.Behaviour.exception

  @optional_callbacks keys: 1
  @callback keys(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @optional_callbacks to_list: 1
  @callback to_list(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [{Mnemonix.key, Mnemonix.value}] | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @optional_callbacks values: 1
  @callback values(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, [Mnemonix.key] | {:error, module}} | Mnemonix.Store.Behaviour.exception

  ####
  # Enumerable Protocol
  ##

  @optional_callbacks enumerable_count: 1
  @callback enumerable_count(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t, non_neg_integer | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @optional_callbacks enumerable_member?: 2
  @callback enumerable_member?(Mnemonix.Store.t, {Mnemonix.key, Mnemonix.value})
    :: {:ok, Mnemonix.Store.t, boolean | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @optional_callbacks enumerable_reduce: 3
  @callback enumerable_reduce(Mnemonix.Store.t, Enumerable.acc, Enumerable.reducer)
    :: {:ok, Mnemonix.Store.t, Enumerable.result} | Mnemonix.Store.Behaviour.exception

  ####
  # Collectable Protocol
  ##

  @optional_callbacks collectable_into: 2
  @callback collectable_into(Mnemonix.Store.t, Enumerable.t)
    :: {:ok, Mnemonix.Store.t, Enumerable.t | {:error, module}} | Mnemonix.Store.Behaviour.exception

  @doc false
  defmacro __using__(_) do
    quote do

      @behaviour unquote __MODULE__

      ####
      # Mnemonix.Store.Behaviours.Enumerable
      ##

      @doc false
      def enumerable?(store) do
        {:ok, store, false}
      end
      defoverridable enumerable?: 1

      @doc false
      def to_enumerable(_store) do
        {:raise, Mnemonix.Features.Enumerable.Error, [module: __MODULE__]}
      end
      defoverridable to_enumerable: 1

      @doc false
      def keys(store) do
        {:ok, store, {:default, __MODULE__}}
      end
      defoverridable keys: 1

      @doc false
      def to_list(store) do
        {:ok, store, {:default, __MODULE__}}
      end
      defoverridable to_list: 1

      @doc false
      def values(store) do
        {:ok, store, {:default, __MODULE__}}
      end
      defoverridable values: 1

      ####
      # Enumerable Protocol
      ##

      @doc false
      def enumerable_count(store) do
        {:ok, store, {:error, __MODULE__}}
      end
      defoverridable enumerable_count: 1

      @doc false
      def enumerable_member?(store, {_key, _value}) do
        {:ok, store, {:error, __MODULE__}}
      end
      defoverridable enumerable_member?: 2

      @doc false
      def enumerable_reduce(store, _acc, _reducer) do
        {:ok, store, {:error, __MODULE__}}
      end
      defoverridable enumerable_reduce: 3

      ####
      # Collectable Protocol
      ##

      @doc false
      def collectable_into(store, _shape) do
        {:ok, store, {:error, __MODULE__}}
      end
      defoverridable collectable_into: 2

    end
  end

end
