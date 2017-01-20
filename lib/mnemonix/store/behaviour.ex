defmodule Mnemonix.Store.Behaviour do
  @moduledoc false

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type t :: Module.t

  @typedoc """
  An instruction to the Mnemonix.Store.server to rais an error in the client.
  """
  @type exception :: {:raise, Module.t, raise_opts :: Keyword.t}

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      use Mnemonix.Store.Behaviours.Core
      use Mnemonix.Store.Behaviours.Map
      use Mnemonix.Store.Behaviours.Expiry
      use Mnemonix.Store.Behaviours.Bump

      @store __MODULE__ |> Inspect.inspect(%Inspect.Opts{})

      @doc """
      Starts a new `Mnemonix.Store` using the `#{@store}` module with `options`.

      The `options` are the same as described in `Mnemonix.Store.Server.start_link/2`.

      The returned `t:GenServer.server/0` reference can be used as the primary
      argument to the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = #{@store}.start_link
          iex> Mnemonix.put(store, :foo, "bar")
          iex> Mnemonix.fetch(store, :foo)
          {:ok, "bar"}
          iex> Mnemonix.delete(store, :foo)
          iex> Mnemonix.fetch(store, :foo)
          :error
      """
      @spec start_link()                  :: GenServer.on_start
      @spec start_link(Mnemonix.Store.Server.options) :: GenServer.on_start
      def start_link(options \\ []) do
        Mnemonix.Store.Server.start_link(__MODULE__, options)
      end

    end
  end

end
