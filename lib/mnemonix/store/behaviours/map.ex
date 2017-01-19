defmodule Mnemonix.Store.Behaviours.Map do
  @moduledoc false

  use Mnemonix.Store.Types, [:store, :key, :value, :exception]

  @optional_callbacks fetch!: 2
  @callback fetch!(store, key) :: {:ok, store, value} | exception

  @optional_callbacks get: 2
  @callback get(store, key) :: {:ok, store, value} | exception

  @optional_callbacks get: 3
  @callback get(store, key, value) :: {:ok, store, value} | exception

  @optional_callbacks get_and_update: 3
  @callback get_and_update(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks get_and_update!: 3
  @callback get_and_update!(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks get_lazy: 3
  @callback get_lazy(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks has_key?: 2
  @callback has_key?(store, key) :: {:ok, store, boolean} | exception

  @optional_callbacks pop: 2
  @callback pop(store, key) :: {:ok, store, value} | exception

  @optional_callbacks pop: 3
  @callback pop(store, key, value) :: {:ok, store, value} | exception

  @optional_callbacks pop_lazy: 3
  @callback pop_lazy(store, key, fun) :: {:ok, store, value} | exception

  @optional_callbacks put_new: 3
  @callback put_new(store, key, value) :: {:ok, store} | exception

  @optional_callbacks put_new_lazy: 3
  @callback put_new_lazy(store, key, fun) :: {:ok, store} | exception

  @optional_callbacks update: 4
  @callback update(store, key, value, fun) :: {:ok, store} | exception

  @optional_callbacks update!: 3
  @callback update!(store, key, fun) :: {:ok, store} | exception

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__

      @doc false
      def fetch!(store, key) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> {:raise, KeyError, [key: key, term: store.impl]}
            {:ok, value} -> {:ok, store, value}
          end
        end
      end
      defoverridable fetch!: 2

      @doc false
      def get(store, key, default \\ nil) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> {:ok, store, default}
            {:ok, value} -> {:ok, store, value}
          end
        end
      end
      defoverridable get: 2, get: 3

      @doc false
      def get_and_update(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          value = case current do
            :error       -> nil
            {:ok, value} -> value
          end

          case fun.(value) do
            {return, new} -> with {:ok, store} <- put(store, key, new) do
              {:ok, store, return}
            end
            :pop          -> with {:ok, store} <- delete(store, key) do
              {:ok, store, value}
            end
          end
        end
      end
      defoverridable get_and_update: 3

      @doc false
      def get_and_update!(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error       -> {:raise, KeyError, [key: key, term: store.impl]}
            {:ok, value} -> case fun.(value) do
              {return, new} -> with {:ok, store} <- put(store, key, new) do
                {:ok, store, return}
              end
              :pop          -> with {:ok, store, value} <- pop(store, key) do
                {:ok, store, value}
              end
            end
          end
        end
      end
      defoverridable get_and_update!: 3

      @doc false
      def get_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, current} <- fetch(store, key) do
          value = case current do
            :error       -> fun.()
            {:ok, value} -> value
          end
          {:ok, store, value}
        end
      end
      defoverridable get_lazy: 3

      @doc false
      def has_key?(store, key) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> {:ok, store, false}
            _value -> {:ok, store, true}
          end
        end
      end
      defoverridable has_key?: 2

      @doc false
      def pop(store, key, default \\ nil) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error       -> {:ok, store, default}
            {:ok, value} -> with {:ok, store} <- delete(store, key) do
              {:ok, store, value}
            end
          end
        end
      end
      defoverridable pop: 2, pop: 3

      @doc false
      def pop_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error       -> {:ok, store, fun.()}
            {:ok, value} -> with {:ok, store} <- delete(store, key) do
              {:ok, store, value}
            end
          end
        end
      end
      defoverridable pop_lazy: 3

      @doc false
      def put_new(store, key, value) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> put(store, key, value)
            _value -> {:ok, store}
          end
        end
      end
      defoverridable put_new: 3

      @doc false
      def put_new_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> put(store, key, fun.())
            _value -> {:ok, store}
          end
        end
      end
      defoverridable put_new_lazy: 3

      @doc false
      def update(store, key, initial, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            {:ok, value} -> put(store, key, fun.(value))
            :error       -> put(store, key, initial)
          end
        end
      end
      defoverridable update: 4

      @doc false
      def update!(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            {:ok, value} -> put(store, key, fun.(value))
            :error       -> {:raise, KeyError, [key: key, term: store.impl]}
          end
        end
      end
      defoverridable update!: 3

    end
  end

end
