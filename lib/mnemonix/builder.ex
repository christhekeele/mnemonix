defmodule Mnemonix.Builder do
  @moduledoc false

  defmacro __using__(opts) do
    quote location: :keep do
      use Mnemonix.Features.Core, unquote(opts)
      use Mnemonix.Features.Map, unquote(opts)
      use Mnemonix.Features.Bump, unquote(opts)
      use Mnemonix.Features.Expiry, unquote(opts)
    end
  end

end
