defmodule Mnemonix.Store.Expiry.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Expiry.Functions
    end
  end

  alias Mnemonix.Store

  @typep store :: Store.t

  @typep opts  :: Store.opts
  @typep state :: Store.state

  @typep key   :: Store.key
  @typep value :: Store.value
  @typep ttl   :: Store.ttl

  @typep exception :: Exception.t
  @typep info      :: term


  ####
  # OPTIONAL
  ##

  @optional_callbacks setup_expiry: 1
  @doc """
  Prepares this store to track the expiration of its entries.
  """
  @callback setup_expiry(store) :: {:ok, state} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

  @doc """
  Sets the entry under `key` to expire after `ttl` seconds.
  """
  @callback expires(store, key, ttl) :: term

end
