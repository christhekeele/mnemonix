defmodule Mnemonix.Store.Behaviours.Expiry do
  @moduledoc false

  @callback setup_expiry(Mnemonix.Store.t)
    :: {:ok, Mnemonix.Store.t} | {:error, reason}
      when reason: :normal | :shutdown | {:shutdown, term} | term

  @callback expire(Mnemonix.Store.t, Mnemonix.key, Mnemonix.Features.Bump.ttl)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback persist(Mnemonix.Store.t, Mnemonix.key)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @callback put_and_expire(Mnemonix.Store.t, Mnemonix.key, Mnemonix.value, Mnemonix.Features.Bump.ttl)
    :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour unquote __MODULE__

      alias Mnemonix.Store.Expiry

      @impl unquote __MODULE__
      def setup_expiry(store = %Mnemonix.Store{opts: opts}) do
        with {:ok, engine} <- Expiry.Engine.start_link(opts) do
          {:ok, %{store | expiry: engine}}
        end
      end

      @impl unquote __MODULE__
      def expire(store, key, ttl) do
        with :ok <- Expiry.Engine.expire(store, key, ttl) do
          {:ok, store}
        end
      end

      @impl unquote __MODULE__
      def persist(store, key) do
        with :ok <- Expiry.Engine.persist(store, key) do
          {:ok, store}
        end
      end

      @impl unquote __MODULE__
      def put_and_expire(store, key, value, ttl) do
        with {:ok, store} <- put(store, key, value),
             {:ok, store} <- expire(store, key, ttl),
        do: {:ok, store}
      end

    end
  end

end
