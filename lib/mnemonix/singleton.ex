defmodule Mnemonix.Singleton do
  @moduledoc false
  
  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      alias Mnemonix.Store
      
      @module unquote(__CALLER__.module)
      
      def singleton, do: @module
      
      @typep store   :: Atom.t
      @typep adapter :: Store.adapter
      @typep opts    :: Store.opts
      @typep key     :: Store.key
      @typep value   :: Store.value
      
      @spec start_link(adapter)                            :: GenServer.on_start
      @spec start_link(adapter, GenServer.options)         :: GenServer.on_start
      @spec start_link({adapter, opts})                    :: GenServer.on_start
      @spec start_link({adapter, opts}, GenServer.options) :: GenServer.on_start
      
      def start_link(init, opts \\ [])
      def start_link(adapter, opts) when not is_tuple adapter do
        Mnemonix.Store.start_link({adapter, []}, Keyword.put(opts, :name, __MODULE__))
      end
      def start_link(init, opts) do
        Mnemonix.Store.start_link(init, Keyword.put(opts, :name, __MODULE__))
      end

    ####  
    # CORE
    ##

      @doc """
      Deletes the entries in `#{@module}` for a specific `key`.

      If the `key` does not exist, the contents of `#{@module}` will be unaffected.

      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.get(:a)
          1
          iex> #{@module}.delete(:a)
          iex> #{@module}.get(:a)
          nil
      """
      @spec delete(key) :: store | no_return
      def delete(key), do: Mnemonix.delete(@module, key)

      # TODO: expiry
      # @doc """
      # Sets the entry under `key` to expire in `ttl` seconds.
      # 
      # If the `key` does not exist, the contents of `#{@module}` will be unaffected.
      # 
      # ## Examples
      
      #     iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
      #     iex> #{@module}.expires(:a, 100)
      #     iex> :timer.sleep(101)
      #     iex> #{@module}.get(:a)
      #     nil
      # """
      # @spec expires(key, ttl) :: store | no_return
      # def expires(key, ttl), do: Mnemonix.expires(@module, key, ttl)
       
      @doc """
      Fetches the value for a specific `key` and returns it in a tuple.
     
      If the `key` does not exist, returns `:error`.
     
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.fetch(:a)
          {:ok, 1}
          iex> #{@module}.fetch(:b)
          :error
      """
      @spec fetch(key) :: {:ok, value} | :error | no_return
      def fetch(key), do: Mnemonix.fetch(@module, key)
      
      @doc """
      Puts the given `value` under `key`.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.get(:b)
          nil
          iex> #{@module}.put(:b, 2)
          iex> #{@module}.get(:b)
          2
      """
      @spec put(key, value) :: store | no_return
      def put(key, value), do: Mnemonix.put(@module, key, value)

    ####  
    # MAP FUNCTIONS
    ##
     
      @doc """
      Fetches the value for specific `key`.
     
      If `key` does not exist, a `KeyError` is raised.
     
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.fetch!(:a)
          1
          iex> #{@module}.fetch!(:b)
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
      """
      @spec fetch!(key) :: {:ok, value} | :error | no_return
      def fetch!(key), do: Mnemonix.fetch!(@module, key)
      
      @doc """
      Gets the value for a specific `key`.
      
      If `key` does not exist, returns `nil`.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.get(:a)
          1
          iex> #{@module}.get(:b)
          nil
      """
      @spec get(key) :: value | no_return
      def get(key), do: Mnemonix.get(@module, key)
      
      @doc """
      Gets the value for a specific `key` with `default`.
       
      If `key` does not exist, returns `default`.
       
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.get(:a, 2)
          1
          iex> #{@module}.get(:b, 2)
          2
      """
      @spec get(key, value) :: value | no_return
      def get(key, default), do: Mnemonix.get(@module, key, default)
      
      @doc """
      Gets the value from `key` and updates it, all in one pass.
      
      This `fun` argument receives the value of `key` (or `nil` if `key`
      is not present) and must return a two-element tuple: the "get" value
      (the retrieved value, which can be operated on before being returned)
      and the new value to be stored under `key`. The `fun` may also
      return `:pop`, implying the current value shall be removed
      from `#{@module}` and returned.
      
      The returned value is a tuple with the "get" value returned by
      `fun` and a reference to `#{@module}` with the updated value under `key`.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module}} = #{@module}.get_and_update(:a, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          iex> value
          1
          iex> #{@module}.get(:a)
          "new value!"
          
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module}} = #{@module}.get_and_update(:b, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          iex> value
          nil
          iex> #{@module}.get(:b)
          "new value!"
          
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module}} = #{@module}.get_and_update(:a, fn _ -> :pop end)
          iex> value
          1
          iex> #{@module}.get(:a)
          nil
          
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module}} = #{@module}.get_and_update(:b, fn _ -> :pop end)
          iex> value
          nil
          iex> #{@module}.get(:b)
          nil
      """
      @spec get_and_update(key, (value -> {get, value} | :pop)) :: {get, store} | no_return when get: term
      def get_and_update(key, fun), do: Mnemonix.get_and_update(@module, key, fun)
      
      @doc """
      Gets the value from `key` and updates it. Raises if there is no `key`.
      
      This `fun` argument receives the value of `key` and must return a
      two-element tuple: the "get" value (the retrieved value, which can be
      operated on before being returned) and the new value to be stored under
      `key`.
      
      The returned value is a tuple with the "get" value returned by `fun` and a
      a reference to `#{@module}` with the updated value under `key`.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module} = #{@module}.get_and_update!(:a, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          iex> value
          1
          iex> #{@module}.get(:a)
          "new value!"
          
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module} = #{@module}.get_and_update!(:b, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
          
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module} = #{@module}.get_and_update!(:a, fn _ -> :pop end)
          iex> value
          1
          iex> #{@module}.get(:a)
          nil
          
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module} = #{@module}.get_and_update!(:b, fn _ -> :pop end)
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
      """
      @spec get_and_update!(key, (value -> {get, value})) :: {get, store} | no_return when get: term
      def get_and_update!(key, fun), do: Mnemonix.get_and_update!(@module, key, fun)
      
      @doc """
      Gets the value for a specific `key`.
      
      If `key` does not exist, lazily evaluates `fun` and returns its result.
      
      This is useful if the default value is very expensive to calculate or
      generally difficult to setup and teardown again.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> #{@module}.get_lazy(:a, fun)
          1
          iex> #{@module}.get_lazy(:b, fun)
          13
      """
      @spec get_lazy(key, (() -> value)) :: value | no_return
      def get_lazy(key, fun) when is_function(fun, 0), do: Mnemonix.get_lazy(@module, key, fun)
      
      @doc """
      Returns whether a given `key` exists in `#{@module}`.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.has_key?(:a)
          true
          iex> #{@module}.has_key?(:b)
          false
      """
      @spec has_key?(key) :: boolean
      def has_key?(key), do: Mnemonix.has_key?(@module, key)
        
      @doc """
      Returns and removes the value associated with `key` in `#{@module}`.
      
      If no value is associated with the `key`, `nil` is returned.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module} = #{@module}.pop(:a)
          iex> value
          1
          iex> #{@module}.get(:a)
          nil
          iex> {value, ^#{@module} = #{@module}.pop(store, :b)
          iex> value
          nil
      """
      @spec pop( key) :: {value, store}
      def pop(key), do: Mnemonix.pop(@module, key)
      
      
      @doc """
      Returns and removes the value associated with `key` in `#{@module}` with `default`.
      
      If no value is associated with the `key` but `default` is given,
      that will be returned instead without touching the store.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@module} = #{@module}.pop(:a)
          iex> value
          nil
          iex> {value, ^#{@module} = #{@module}.pop(:b, 2)
          iex> value
          2
      """
      @spec pop(key, term) :: {value, store}
      def pop(key, default), do: Mnemonix.pop(@module, key, default)
      
      @doc """
      Lazily returns and removes the value associated with `key` in `#{@module}`.
      
      This is useful if the default value is very expensive to calculate or
      generally difficult to setup and teardown again.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> {value, ^#{@module} = #{@module}.pop_lazy(:a, fun)
          iex> value
          1
          iex> {value, ^#{@module} = #{@module}.pop_lazy(:b, fun)
          iex> value
          13
      """
      @spec pop_lazy(key, (() -> value)) :: {value, store}
      def pop_lazy(key, fun) when is_function(fun, 0), do: Mnemonix.pop_lazy(@module, key, fun)
      
      @doc """
      Puts the given `value` under `key` unless the entry `key`
      already exists.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.put_new(:b, 2)
          iex> #{@module}.get(:b)
          2
          iex> #{@module}.put_new(:b, 3)
          iex> #{@module}.get(:b)
          2
      """
      @spec put_new(key, value) :: store
      def put_new(key, value), do: Mnemonix.put_new(@module, key, value)
      
      @doc """
      Evaluates `fun` and puts the result under `key`
      in `#{@module}` unless `key` is already present.
      
      This is useful if the value is very expensive to calculate or
      generally difficult to setup and teardown again.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> #{@module}.put_new_lazy(:b, fun)
          iex> #{@module}.get(:b)
          13
          iex> #{@module}.put_new_lazy(:a, fun)
          iex> #{@module}.get(:a)
          1
      """
      @spec put_new_lazy(key, (() -> value)) :: store | no_return
      def put_new_lazy(key, fun) when is_function(fun, 0), do: Mnemonix.put_new_lazy(@module, key, fun)
      
      # TODO:
      # split(keys)
      #   Takes all entries corresponding to the given keys and extracts them into a map
        
      # TODO:
      # take(keys)
      #   Takes all entries corresponding to the given keys and returns them in a map
      
      @doc """
      Updates the `key` in `#{@module}` with the given function.
      
      If the `key` does not exist, inserts the given `initial` value.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.update(:a, 13, &(&1 * 2))
          iex> #{@module}.get(:a)
          2
          iex> #{@module}.update(:b, 13, &(&1 * 2))
          iex> #{@module}.get(:b)
          13
      """
      @spec update(key, value, (value -> value)) :: store | no_return
      def update(key, initial, fun), do: Mnemonix.update(@module, key, initial, fun)
      
      @doc """
      Updates the `key` with the given function.
      
      If the `key` does not exist, raises `KeyError`.
      
      ## Examples
      
          iex> #{@module}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@module}.update!(:a, &(&1 * 2))
          iex> #{@module}.get(:a)
          2
          iex> #{@module}.update!(:b, &(&1 * 2))
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
      """
      @spec update!(key, (value -> value)) :: store | no_return
      def update!(key, fun), do: Mnemonix.update!(@module, key, fun)
      
    end
  end
      
end