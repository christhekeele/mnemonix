defmodule Mnemonix.Builder do
  @moduledoc """
  Creates functions that proxy to Mnemonix ones.

  `use Mnemonix.Builder` to instrument a module with the `Mnemonix` client API.
  It will define the `Mnemonix.Supervision` functions and all `Mnemonix.Feature` functions on the module:

  - `Mnemonix.Features.Map`
  - `Mnemonix.Features.Bump`
  - `Mnemonix.Features.Expiry`
  - `Mnemonix.Features.Enumerable`

  This allows you to define a custom Mnemonix client API:

      iex> defmodule My.Store.API do
      ...>   use Mnemonix.Builder
      ...> end
      iex> {:ok, store} = My.Store.API.start_link
      iex> My.Store.API.get(store, :a)
      nil
      iex> My.Store.API.put(store, :a, 1)
      iex> My.Store.API.get(store, :a)
      1

  If you want to create a Mnemonix client API with access to only a subset of Mnemonix features, simply
  use those modules as you would the `Mnemonix.Builder` itself.

  #### Documentation

  By default, the builder will include the `@doc` for each function.
  To disable this and leave the functions undocumented, provide `docs: false` when using.

  #### Inlining

  Additionally, all functions are defined as simple delegates to their source module.
  If you would rather have their implementations inlined into your module for a small performance boost at the cost
  of longer compile times, provide the `inline: true` option when using.

  #### Singletons

  You can pass in the `singleton: true` option to have your module use its own name
  as a store reference, omitting the need for the first argument to all `Mnemonix.Feature` functions:

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

    Singletons use their own module names as references names to work.
    You can change the name used when defining the singleton:

      iex> defmodule My.Singleton.Interface do
      ...>   use Mnemonix.Builder, singleton: :store
      ...> end
      iex> My.Singleton.Interface.singleton
      :store
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
    {singleton, opts} = Mnemonix.Singleton.Behaviour.establish_singleton(__CALLER__.module, opts)
    store = if singleton, do: Mnemonix.Singleton.Behaviour.determine_singleton(__CALLER__.module, Keyword.get(opts, :singleton))

    if singleton do
      quote location: :keep do
        @doc """
        Retreives the name of the GenServer that this singleton makes calls to.
        """
        def singleton, do: unquote(store)

        use Mnemonix.Supervision, unquote(opts)

        use Mnemonix.Features.Map.Singleton, unquote(opts)
        use Mnemonix.Features.Bump.Singleton, unquote(opts)
        # use Mnemonix.Features.Expiry.Singleton, unquote(opts) #TODO
        use Mnemonix.Features.Enumerable.Singleton, unquote(opts)
      end
    else
      quote location: :keep do
        use Mnemonix.Supervision, unquote(opts)

        use Mnemonix.Features.Map, unquote(opts)
        use Mnemonix.Features.Bump, unquote(opts)
        # use Mnemonix.Features.Expiry, unquote(opts) #TODO
        use Mnemonix.Features.Enumerable, unquote(opts)
      end
    end
  end

end
