defmodule Mnemonix.Store.Behaviour.Default do
  @moduledoc false
  
  defmacro __using__(_) do
    quote location: :keep do
      
      def drop(store, keys) do
        {:ok, keys
          |> Enum.to_list
          |> drop_list(store)
        }
      end

      defp drop_list([], store), do: store
      defp drop_list([key | rest], store) do
        with {:ok, store} <- delete(store, key) do
          drop_list(rest, store)
        end
      end
      
      def fetch!(store, key) do
        with {:ok, store, :error} <- fetch(store, key) do
          {:raise, KeyError, [key: key, term: store]}
        end
      end
      
      def get(store, key, default \\ nil) do
        with {:ok, store, :error} <- fetch(store, key) do
          {:ok, store, default}
        end
      end
      
      def get_and_update(store, key, fun) do
        with {:ok, store, value} <- fetch(store, key) do
          current = case value do
            :error -> nil
            value  -> value
          end
          
          case fun.(current) do
            {get, update} -> with {:ok, store} <- put(store, key, update) do
              {:ok, store, get}
            end
            :pop          -> with {:ok, store} <- delete(store, key) do
              {:ok, store, current}
            end
          end
        end
      end
      
      def get_and_update!(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          if current == :error do
            {:raise, KeyError, [key: key, term: store]}
          else
            case fun.(current) do
              {get, update} -> with {:ok, store} <- put(store, key, update) do
                {:ok, store, get}
              end
              :pop          -> with {:ok, store, value} <- pop(store, key) do
                {:ok, store, value}
              end
            end
          end
        end
      end
      
      def get_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, :error} <- fetch(store, key) do
          {:ok, store, fun.()}
        end
      end
      
      def has_key?(store, key) do
        with {:ok, store, keys} <- keys(store) do
          {:ok, store, key in keys}
        end
      end
      
      def pop(store, key, default \\ nil) do
        with {:ok, store, exists} <- has_key?(store, key) do
          if exists do
            with {:ok, store, value} <- get(store, key) do
              {:ok, store, value}
            end
          else
            {:ok, store, default}
          end
        end
      end
      
      def pop_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, value} <- fetch(store, key) do
          if value == :error do
            {:ok, store, fun.()}
          else
            with {:ok, store} <- delete(store, key) do
              {:ok, store, value}
            end
          end
        end
      end
      
      def put_new(store, key, value) do
        with {:ok, store, exists} <- has_key?(store, key) do
          if exists do
            {:ok, store}
          else
            put(store, key, value)
          end
        end
      end
      
      def put_new_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, exists} <- has_key?(store, key) do
          if exists do
            {:ok, store}
          else
            put(store, key, fun.())
          end
        end
      end
      
      def update(store, key, initial, fun) do
        with {:ok, store, value} <- fetch(store, key) do
          if value == :error do
            put(store, key, initial)
          else
            put(store, key, fun.(value))
          end
        end
      end
      
      def update!(store, key, fun) do
        with {:ok, store, value} <- fetch(store, key) do
          if value == :error do
            {:raise, KeyError, [key: key, term: store]}
          else
            put(store, key, fun.(value))
          end
        end
      end
      
    end
  end
  
end
