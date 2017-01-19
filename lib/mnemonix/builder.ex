defmodule Mnemonix.Builder do
  @moduledoc """
  Creates functions that proxy to Mnemonix ones.

  `use Mnemonix.Builder` to add all `Mnemonix.Feature` functions to a module.

  You can pass in the option `singleton: true` to create a module that uses its own name
  as a GenServer reference, and skips the first argument to all Mnemonix functions:

  ```elixir
  iex> defmodule My.Store do
  ...>   use Mnemonix.Builder, singleton: true
  ...>   def start_link do
  ...>     Mnemonix.Store.Server.start_link(Mnemonix.Stores.ETS, name: __MODULE__)
  ...>   end
  ...> end
  iex> My.Store.start_link
  iex> My.Store.get(:a)
  nil
  iex> My.Store.put(:a, 1)
  iex> My.Store.get(:a)
  1
  """

  defmacro __using__(opts) do
    quote location: :keep do
      use Mnemonix.Features.Core, unquote(opts)
      use Mnemonix.Features.Map, unquote(opts)
      use Mnemonix.Features.Bump, unquote(opts)
      use Mnemonix.Features.Expiry, unquote(opts)
    end
  end

end
