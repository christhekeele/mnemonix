defmodule Mnemonix.Builder do
  @moduledoc """
  Creates functions that proxy to Mnemonix ones.

  `use Mnemonix.Builder` to add all `Mnemonix.Feature` functions to a module:

      iex> defmodule My.Store do
      ...>   use Mnemonix.Builder
      ...> end
      iex> {:ok, store} = My.Store.start_link
      iex> My.Store.get(store, :a)
      nil
      iex> My.Store.put(store, :a, 1)
      iex> My.Store.get(store, :a)
      1

  You can pass in the `:singleton` option to create a module that uses its own name
  as a store reference, omitting the need for the first argument to all
  `Mnemonix.Feature` functions:

      iex> defmodule My.Singleton do
      ...>   use Mnemonix.Builder, singleton: true
      ...> end
      iex> My.Singleton.start_link
      iex> My.Singleton.get(:a)
      nil
      iex> My.Singleton.put(:a, 1)
      iex> My.Singleton.get(:a)
      1

  Singletons still play nicely with the standard `Mnemonix` functions:

      iex> defmodule My.Other.Singleton do
      ...>   use Mnemonix.Builder, singleton: true
      ...> end
      iex> My.Other.Singleton.start_link
      iex> My.Other.Singleton.get(:a)
      nil
      iex> Mnemonix.get(My.Other.Singleton, :a)
      nil
      iex> Mnemonix.put(My.Other.Singleton, :a, 1)
      iex> My.Other.Singleton.get(:a)
      1

    Singletons use their own names as references names to work.
    You can change the name used when defining the singleton:

      iex> defmodule My.Singleton.Interface do
      ...>   use Mnemonix.Builder, singleton: :store
      ...> end
      iex> My.Singleton.Interface.start_link
      iex> My.Singleton.Interface.get(:a)
      nil
      iex> Mnemonix.get(:store, :a)
      nil
      iex> Mnemonix.put(:store, :a, 1)
      iex> My.Singleton.Interface.get(:a)
      1
  """

  defmacro __using__(opts) do
    quote do
      use Mnemonix.Features.Map, unquote(opts)
      use Mnemonix.Features.Bump, unquote(opts)
      use Mnemonix.Features.Expiry, unquote(opts)
      use Mnemonix.Features.Enumerable, unquote(opts)
      use Mnemonix.Features.Supervision, unquote(opts)
    end
  end

end
