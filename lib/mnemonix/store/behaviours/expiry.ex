defmodule Mnemonix.Store.Behaviours.Expiry do
  @moduledoc false

  # alias Mnemonix.Store.Expiry #TODO
  #
  # use Mnemonix.Behaviour
  #
  # @callback setup_expiry(Mnemonix.Store.t)
  #   :: {:ok, Mnemonix.Store.t} | {:error, reason}
  #     when reason: :normal | :shutdown | {:shutdown, term} | term
  # @doc false
  # @spec setup_expiry(Mnemonix.Store.t)
  #   :: {:ok, Mnemonix.Store.t} | {:error, reason}
  #     when reason: :normal | :shutdown | {:shutdown, term} | term
  # def setup_expiry(store = %Store{opts: opts}) do
  #   with {:ok, engine} <- Expiry.Engine.start_link(opts) do
  #     {:ok, %{store | expiry: engine}}
  #   end
  # end
  #
  # @callback expire(Mnemonix.Store.t, Mnemonix.key, Mnemonix.Features.Bump.ttl)
  #   :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  # @doc false
  # @spec expire(Mnemonix.Store.t, Mnemonix.key, Mnemonix.Features.Bump.ttl)
  #   :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  # def expire(store, key, ttl) do
  #   with :ok <- Expiry.Engine.expire(store, key, ttl) do
  #     {:ok, store}
  #   end
  # end
  #
  # @callback persist(Mnemonix.Store.t, Mnemonix.key)
  #   :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  # @doc false
  # @spec persist(Mnemonix.Store.t, Mnemonix.key)
  #   :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  # def persist(store, key) do
  #   with :ok <- Expiry.Engine.persist(store, key) do
  #     {:ok, store}
  #   end
  # end
  #
  # @callback put_and_expire(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value, Mnemonix.Features.Bump.ttl)
  #   :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  # @doc false
  # @spec put_and_expire(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value, Mnemonix.Features.Bump.ttl)
  #   :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
  # def put_and_expire(store, key, value, ttl) do
  #   with {:ok, store} <- store.impl.put(store, key, value),
  #        {:ok, store} <- expire(store, key, ttl),
  #   do: {:ok, store}
  # end

end
