defmodule Mnemonix.API do
  @moduledoc """
  Provides functions to make calls to a running `Mnemonix.Store` server.
  """

  @doc """
  Provides functions to make calls to a running `Mnemonix.Store` server.
  """
  defmacro __using__(_) do
    quote location: :keep do

      defdelegate delete(store, key),     to: Mnemonix.Core.Functions
      defdelegate fetch(store, key),      to: Mnemonix.Core.Functions
      defdelegate put(store, key, value), to: Mnemonix.Core.Functions

      defdelegate fetch!(store, key),               to: Mnemonix.Map.Functions
      defdelegate get(store, key),                  to: Mnemonix.Map.Functions
      defdelegate get(store, key, default),         to: Mnemonix.Map.Functions
      defdelegate get_and_update(store, key, fun),  to: Mnemonix.Map.Functions
      defdelegate get_and_update!(store, key, fun), to: Mnemonix.Map.Functions
      defdelegate get_lazy(store, key, fun),        to: Mnemonix.Map.Functions
      defdelegate has_key?(store, key),             to: Mnemonix.Map.Functions
      defdelegate pop(store, key),                  to: Mnemonix.Map.Functions
      defdelegate pop(store, key, default),         to: Mnemonix.Map.Functions
      defdelegate pop_lazy(store, key, fun),        to: Mnemonix.Map.Functions
      defdelegate put_new(store, key, value),       to: Mnemonix.Map.Functions
      defdelegate put_new_lazy(store, key, fun),    to: Mnemonix.Map.Functions
      defdelegate update(store, key, initial, fun), to: Mnemonix.Map.Functions
      defdelegate update!(store, key, fun),         to: Mnemonix.Map.Functions

      defdelegate bump(store, key, amount),      to: Mnemonix.Bump.Functions
      defdelegate bump!(store, key, amount),     to: Mnemonix.Bump.Functions
      defdelegate increment(store, key),         to: Mnemonix.Bump.Functions
      defdelegate increment(store, key, amount), to: Mnemonix.Bump.Functions
      defdelegate decrement(store, key),         to: Mnemonix.Bump.Functions
      defdelegate decrement(store, key, amount), to: Mnemonix.Bump.Functions

      defdelegate expire(store, key, ttl),                to: Mnemonix.Expiry.Functions
      defdelegate persist(store, key),                    to: Mnemonix.Expiry.Functions
      defdelegate put_and_expire(store, key, value, ttl), to: Mnemonix.Expiry.Functions

    end
  end

end
