defmodule Mnemonix.Store.Behaviour do
  @moduledoc false

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type t :: Module.t

  @typedoc """
  Options for a `Mnemonix.Store.Behaviour` child specification.
  """
  @type options :: [
    otp_app: atom,
    store: Mnemonix.Store.options,
    server: GenServer.options,
  ]

  @typedoc """
  An instruction to a `Mnemonix.Store.Server` to raise an error in the client.
  """
  @type exception :: {:raise, Module.t, raise_opts :: Keyword.t}

  @doc false
  defmacro __using__(opts \\ []) do
    quote location: :keep do
      @behaviour Mnemonix.Store.Translator

      use Mnemonix.Store.Behaviours.Core, unquote(opts)
      use Mnemonix.Store.Behaviours.Map, unquote(opts)
      use Mnemonix.Store.Behaviours.Bump, unquote(opts)
      # use Mnemonix.Store.Behaviours.Expiry, unquote(opts) #TODO
      use Mnemonix.Store.Behaviours.Enumerable, unquote(opts)
    end
  end

end
