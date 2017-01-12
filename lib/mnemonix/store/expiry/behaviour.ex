defmodule Mnemonix.Store.Expiry.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Expiry.Implementation
    end
  end

  use Mnemonix.Store.Types, [:store, :key, :value, :ttl, :exception]

  @optional_callbacks setup_expiry: 1
  @callback setup_expiry(store) :: {:ok, store} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

  @optional_callbacks expire: 3
  @callback expire(store, key, ttl) :: {:ok, store} | exception

  @optional_callbacks persist: 2
  @callback persist(store, key) :: {:ok, store} | exception

  @optional_callbacks put_and_expire: 4
  @callback put_and_expire(store, key, value, ttl) :: {:ok, store} | exception

end
