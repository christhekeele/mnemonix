defmodule Mnemonix.Store.Behaviour do
  @moduledoc false

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type t :: module

  @doc false
  defmacro __using__(opts \\ []) do
    opts = Keyword.put(opts, :inline, true)

    quote location: :keep do
      @behaviour Mnemonix.Store.Translator

      use Mnemonix.Store.Behaviours.Core, unquote(opts)
      use Mnemonix.Store.Behaviours.Map, unquote(opts)
      use Mnemonix.Store.Behaviours.Bump, unquote(opts)
      use Mnemonix.Store.Behaviours.Expiry, unquote(opts)
      use Mnemonix.Store.Behaviours.Enumerable, unquote(opts)
    end
  end
end
