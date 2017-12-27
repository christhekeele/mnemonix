defmodule Mnemonix.Store.Behaviours.Expiry do
  @moduledoc false

  alias Mnemonix.Store
  alias Mnemonix.Features.Expiry

  use Mnemonix.Behaviour

  @callback setup_expiry(Store.t()) ::
              {:ok, Store.t()} | :ignore | {:stop, reason :: term}
  @doc false
  @spec setup_expiry(Store.t()) ::
              {:ok, Store.t()} | :ignore | {:stop, reason :: term}
  def setup_expiry(%Store{} = store) do
    {:ok, %Store{store | expiry: :ets.new(Module.concat(__MODULE__, Table), [:private])}}
  end

  @callback expire(Store.t, Mnemonix.key, Expiry.ttl)
    :: {:ok, Store.t} | Store.Server.exception
  @doc false
  @spec expire(Store.t, Mnemonix.key, Expiry.ttl)
    :: {:ok, Store.t} | Store.Server.exception
  def expire(%Store{} = store, key, ttl) do
    with :ok <- abort(store, key),
         :ok <- schedule(store, key, ttl),
    do: {:ok, store}
  end

  @callback persist(Store.t, Mnemonix.key)
    :: {:ok, Store.t} | Store.Server.exception
  @doc false
  @spec persist(Store.t, Mnemonix.key)
    :: {:ok, Store.t} | Store.Server.exception
  def persist(%Store{} = store, key) do
    with :ok <- abort(store, key) do
      {:ok, store}
    end
  end

  @callback put_and_expire(Store.t, Mnemonix.key, Mnemonix.value, Expiry.ttl)
    :: {:ok, Store.t} | Store.Server.exception
  @doc false
  @spec put_and_expire(Store.t, Mnemonix.key, Mnemonix.value, Expiry.ttl)
    :: {:ok, Store.t} | Store.Server.exception
  def put_and_expire(%Store{impl: impl} = store, key, value, ttl) do
    with {:ok, store} <- impl.put(store, key, value),
         :ok <- schedule(store, key, ttl),
    do: {:ok, store}
  end

  defp abort(%Store{expiry: expiry}, key) do
    case :ets.take(expiry, key) do
      [{^key, timer}] -> Process.cancel_timer(timer, info: false)
      _ -> :ok
    end
  end

  defp schedule(%Store{expiry: expiry}, key, ttl) do
    with true <- :ets.insert(expiry, {key, Process.send_after(self(), {:expire, key}, ttl)}) do
      :ok
    end
  end
end
