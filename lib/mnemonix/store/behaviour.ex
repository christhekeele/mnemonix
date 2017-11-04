defmodule Mnemonix.Store.Behaviour do
  @moduledoc false

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type t :: Module.t

  @typedoc """
  An instruction to the `Mnemonix.Store.Server` to raise an error in the client.
  """
  @type exception :: {:raise, Module.t, raise_opts :: Keyword.t}

  @doc false
  defmacro __using__(_) do
    quote do

      use Mnemonix.Store.Behaviours.Core
      defoverridable Mnemonix.Store.Behaviours.Core

      use Mnemonix.Store.Behaviours.Map
      defoverridable Mnemonix.Store.Behaviours.Map

      use Mnemonix.Store.Behaviours.Bump
      defoverridable Mnemonix.Store.Behaviours.Bump

      use Mnemonix.Store.Behaviours.Expiry
      defoverridable Mnemonix.Store.Behaviours.Expiry

      use Mnemonix.Store.Behaviours.Enumerable
      defoverridable Mnemonix.Store.Behaviours.Enumerable

      @behaviour Mnemonix.Store.Translator

    end
  end

end
