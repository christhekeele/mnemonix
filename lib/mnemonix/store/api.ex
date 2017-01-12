defmodule Mnemonix.Store.API do
  @moduledoc """
  Provides functions to make calls to a running `Mnemonix.Store` server.
  """

  @doc """
  Provides functions to make calls to a running `Mnemonix.Store` server.
  """
  defmacro __using__(_) do
    quote location: :keep do

      defdelegate delete(store, key),     to: Mnemonix.Store.Core.API
      defdelegate fetch(store, key),      to: Mnemonix.Store.Core.API
      defdelegate put(store, key, value), to: Mnemonix.Store.Core.API

      defdelegate fetch!(store, key),               to: Mnemonix.Store.Map.API
      defdelegate get(store, key),                  to: Mnemonix.Store.Map.API
      defdelegate get(store, key, default),         to: Mnemonix.Store.Map.API
      defdelegate get_and_update(store, key, fun),  to: Mnemonix.Store.Map.API
      defdelegate get_and_update!(store, key, fun), to: Mnemonix.Store.Map.API
      defdelegate get_lazy(store, key, fun),        to: Mnemonix.Store.Map.API
      defdelegate has_key?(store, key),             to: Mnemonix.Store.Map.API
      defdelegate new(),                            to: Mnemonix.Store.Map.API
      defdelegate new(enumerable),                  to: Mnemonix.Store.Map.API
      defdelegate new(enumerable, transform),       to: Mnemonix.Store.Map.API
      defdelegate pop(store, key),                  to: Mnemonix.Store.Map.API
      defdelegate pop(store, key, default),         to: Mnemonix.Store.Map.API
      defdelegate pop_lazy(store, key, fun),        to: Mnemonix.Store.Map.API
      defdelegate put_new(store, key, value),       to: Mnemonix.Store.Map.API
      defdelegate put_new_lazy(store, key, fun),    to: Mnemonix.Store.Map.API
      defdelegate update(store, key, initial, fun), to: Mnemonix.Store.Map.API
      defdelegate update!(store, key, fun),         to: Mnemonix.Store.Map.API

      defdelegate bump(store, key, amount),      to: Mnemonix.Store.Bump.API
      defdelegate bump!(store, key, amount),     to: Mnemonix.Store.Bump.API
      defdelegate increment(store, key),         to: Mnemonix.Store.Bump.API
      defdelegate increment(store, key, amount), to: Mnemonix.Store.Bump.API
      defdelegate decrement(store, key),         to: Mnemonix.Store.Bump.API
      defdelegate decrement(store, key, amount), to: Mnemonix.Store.Bump.API

      defdelegate expire(store, key, ttl),                to: Mnemonix.Store.Expiry.API
      defdelegate persist(store, key),                    to: Mnemonix.Store.Expiry.API
      defdelegate put_and_expire(store, key, value, ttl), to: Mnemonix.Store.Expiry.API

    end
  end

end
