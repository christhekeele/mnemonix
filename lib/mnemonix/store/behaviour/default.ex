defmodule Mnemonix.Store.Behaviour.Default do
  @moduledoc false
  
  defmacro __using__(_) do
    quote location: :keep do

    ####
    # LIFECYCLE
    ##
    
    def teardown(reason, _store) do
      {:ok, reason}
    end
    defoverridable teardown: 2
      
    ####
    # MAP FUNCTIONS
    ##
      
      def fetch!(store, key) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> {:raise, KeyError, [key: key, term: store.adapter]}
            {:ok, value} -> {:ok, store, value}
          end
        end
      end
      defoverridable fetch!: 2
      
      def get(store, key, default \\ nil) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> {:ok, store, default}
            {:ok, value} -> {:ok, store, value}
          end
        end
      end
      defoverridable get: 2, get: 3
      
      def get_and_update(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          value = case current do
            :error       -> nil
            {:ok, value} -> value
          end
          
          case fun.(value) do
            {get, update} -> with {:ok, store} <- put(store, key, update) do
              {:ok, store, get}
            end
            :pop          -> with {:ok, store} <- delete(store, key) do
              {:ok, store, value}
            end
          end
        end
      end
      defoverridable get_and_update: 3
      
      def get_and_update!(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do 
            :error       -> {:raise, KeyError, [key: key, term: store.adapter]}
            {:ok, value} -> case fun.(value) do
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
      defoverridable get_and_update!: 3
      
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
      
      def has_key?(store, key) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> {:ok, store, false}
            _value -> {:ok, store, true}
          end
        end
      end
      defoverridable has_key?: 2
      
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
      
      def put_new(store, key, value) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> put(store, key, value)
            _value -> {:ok, store}
          end
        end
      end
      defoverridable put_new: 3
      
      def put_new_lazy(store, key, fun) when is_function(fun, 0) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error -> put(store, key, fun.())
            _value -> {:ok, store}
          end
        end
      end
      defoverridable put_new_lazy: 3
      
      def update(store, key, initial, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error       -> put(store, key, initial)
            {:ok, value} -> put(store, key, fun.(value))
          end
        end
      end
      defoverridable update: 4
      
      def update!(store, key, fun) do
        with {:ok, store, current} <- fetch(store, key) do
          case current do
            :error       -> {:raise, KeyError, [key: key, term: store.adapter]}
            {:ok, value} -> put(store, key, fun.(value))
          end
        end
      end
      defoverridable update!: 3
      
    end
  end
  
end
