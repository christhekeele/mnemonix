defmodule Mnemonix.API do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      use Mnemonix.Store.Types, [:store, :key, :value, :ttl, :bump_op]

      use Mnemonix.Store.Core.API
      use Mnemonix.Store.Map.API
      use Mnemonix.Store.Bump.API
      use Mnemonix.Store.Expiry.API
    end
  end

end
