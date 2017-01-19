defmodule Mnemonix.Features.Core do
  @moduledoc """
  Invokes core operations on a running Mnemonix.Store.Server.
  """

  defmacro __using__(opts) do
    quote do
      use Mnemonix.Feature, [unquote_splicing(opts), module: unquote(__MODULE__)]
    end
  end

  @doc """
  Removes the entry under `key` in `store`.

  If the `key` does not exist, the contents of `store` will be unaffected.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.get(store, :a)
      1
      iex> Mnemonix.delete(store, :a)
      iex> Mnemonix.get(store, :a)
      nil
  """
  @spec delete(Mnemonix.store, Mnemonix.key)
    :: Mnemonix.store | no_return
  def delete(store, key) do
    case GenServer.call(store, {:delete, key}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Retrievs the value of the entry under `key` in `store`.

  If the `key` does not exist, returns `:error`, otherwise returns
  `{:ok, value}`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.fetch(store, :a)
      {:ok, 1}
      iex> Mnemonix.fetch(store, :b)
      :error
  """
  @spec fetch(Mnemonix.store, Mnemonix.key)
    :: {:ok, Mnemonix.value} | :error | no_return
  def fetch(store, key) do
    case GenServer.call(store, {:fetch, key}) do
      {:ok, value}         -> value
      {:raise, type, args} -> raise type, args
    end
  end

  @doc """
  Creates a new entry for `value` under `key` in `store`.

  ## Examples

      iex> store = Mnemonix.new(%{a: 1})
      iex> Mnemonix.get(store, :b)
      nil
      iex> Mnemonix.put(store, :b, 2)
      iex> Mnemonix.get(store, :b)
      2
  """
  @spec put(Mnemonix.store, Mnemonix.key, Mnemonix.value)
    :: Mnemonix.store | no_return
  def put(store, key, value) do
    case GenServer.call(store, {:put, key, value}) do
      :ok                  -> store
      {:raise, type, args} -> raise type, args
    end
  end

end
