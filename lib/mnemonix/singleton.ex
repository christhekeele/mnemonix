defmodule Mnemonix.Singleton do
  
  defmacro __using__(_) do
    quote location: :keep do
      alias Mnemonix.Store
      
      @module unquote(__CALLER__.module)
      
      @type store :: Atom.t
      @type key   :: Store.key
      @type value :: Store.value
      
      @spec start_link(atom, Keyword.t) :: GenServer.on_start
      def start_link(adapter, opts \\ []), do: Mnemonix.start_link adapter, Keyword.put(opts, :name, @module)

      @doc """
      Deletes the entries in `#{@module}` for a specific `key`.

      If the `key` does not exist, the contents of `#{@module}` will be unaffected.

      ## Examples
          iex> #{@module}.delete(%{a: 1, b: 2}, :a)
          %{b: 2}
          iex> #{@module}.delete(%{b: 2}, :a)
          %{b: 2}
      """
      @spec delete(key) :: store
      def delete(key), do: Mnemonix.delete(@module, key)

      @doc """
      Drops the given `keys` from `#{@module}`.

      ## Examples
          iex> Menmonix.Store.drop([:b, :d])
          %{a: 1, c: 3}
      """
      @spec drop(Enumerable.t) :: store
      def drop(keys), do: Mnemonix.drop(@module, keys)

      @doc """
      Fetches the value for a specific `key` and returns it in a tuple.

      If the `key` does not exist, returns `:error`.

      ## Examples
          iex> #{@module}.fetch(:a)
          {:ok, 1}
          iex> #{@module}.fetch(:b)
          :error
      """
      @spec fetch(key) :: {:ok, value} | :error
      def fetch(key), do: Mnemonix.fetch(@module, key)

      @doc """
      Fetches the value for specific `key`.

      If `key` does not exist, a `KeyError` is raised.

      ## Examples
          iex> #{@module}.fetch!(:a)
          1
          iex> #{@module}.fetch!(:b)
          ** (KeyError) key :b not found in: #{@module}
      """
      @spec fetch!(key) :: value | no_return
      def fetch!(key), do: Mnemonix.fetch!(@module, key)

      @doc """
      Gets the value for a specific `key`.

      If `key` does not exist, return the default value
      (`nil` if no default value).

      ## Examples
          iex> #{@module}.get(:a)
          nil
          iex> #{@module}.get(:a)
          1
          iex> #{@module}.get(:b)
          nil
          iex> #{@module}.get(:b, 3)
          3
      """
      @spec get(key) :: value
      @spec get(key, value) :: value
      def get(key, default \\ nil), do: Mnemonix.get(@module, key, default)

      @doc """
      Gets the value from `key` and updates it, all in one pass.

      This `fun` argument receives the value of `key` (or `nil` if `key`
      is not present) and must return a two-element tuple: the "get" value
      (the retrieved value, which can be operated on before being returned)
      and the new value to be stored under `key`. The `fun` may also
      return `:pop`, implying the current value shall be removed
      from `#{@module}` and returned.

      The returned value is a tuple with the "get" value returned by
      `fun` and a new map with the updated value under `key`.

      ## Examples
          iex> #{@module}.get_and_update(:a, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          {1, #{@module}}
          iex> #{@module}.get_and_update(:b, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          {nil, #{@module}}
          iex> #{@module}.get_and_update(:a, fn _ -> :pop end)
          {1, #{@module}}
          iex> #{@module}.get_and_update(:b, fn _ -> :pop end)
          {nil, #{@module}}
      """
      @spec get_and_update(key, (value -> {get, value} | :pop)) :: {get, store} when get: term
      def get_and_update(key, fun), do: Mnemonix.get_and_update(@module, key, fun)

      @doc """
      Gets the value from `key` and updates it. Raises if there is no `key`.

      This `fun` argument receives the value of `key` and must return a
      two-element tuple: the "get" value (the retrieved value, which can be
      operated on before being returned) and the new value to be stored under
      `key`.

      The returned value is a tuple with the "get" value returned by `fun` and a
      a reference to the `#{@module}` with the updated value under `key`.

      ## Examples
          iex> #{@module}.get_and_update!(:a, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          {1, #{@module}}
          iex> #{@module}.get_and_update!(:b, fn current_value ->
          ...>   {current_value, "new value!"}
          ...> end)
          ** (KeyError) key :b not found
          iex> #{@module}.get_and_update!(:a, fn _ ->
          ...>   :pop
          ...> end)
          {1, #{@module}}
      """
      @spec get_and_update!(key, (value -> {get, value})) :: {get, store} | no_return when get: term
      def get_and_update!(key, fun), do: Mnemonix.get_and_update!(@module, key, fun)

      @doc """
      Gets the value for a specific `key`.

      If `key` does not exist, lazily evaluates `fun` and returns its result.

      This is useful if the default value is very expensive to calculate or
      generally difficult to setup and teardown again.

      ## Examples
          iex> map = %{a: 1}
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> #{@module}.get_lazy(:a, fun)
          1
          iex> #{@module}.get_lazy(:b, fun)
          13
      """
      @spec get_lazy(key, (() -> value)) :: value
      def get_lazy(key, fun) when is_function(fun, 0), do: Mnemonix.get_lazy(@module, key, fun)

      @doc """
      Returns whether a given `key` exists in the given `#{@module}`.

      ## Examples
          iex> #{@module}.has_key?(:a)
          true
          iex> #{@module}.has_key?(:b)
          false
      """
      @spec has_key?(key) :: boolean
      def has_key?(key), do: Mnemonix.has_key?(@module, key)

      @doc """
      Returns all keys from `#{@module}`.

      ## Examples
          iex> #{@module}.keys()
          [:a, :b]
      """
      @spec keys :: [key] | []
      def keys, do: Mnemonix.keys(@module)

      @doc """
      Returns and removes the value associated with `key` in `#{@module}`.

      If no value is associated with the `key` but `default` is given,
      that will be returned instead without touching the store.

      ## Examples
          iex> #{@module}.pop(:a)
          {1, #{@module} }
          iex> #{@module}.pop(:b)
          {nil, #{@module}}
          iex> #{@module}.pop(:b, 3)
          {3, #{@module}}
      """
      @spec pop(key, value) :: {value, store}
      def pop(key, default \\ nil), do: Mnemonix.pop(@module, key, default)

      @doc """
      Lazily returns and removes the value associated with `key` in `#{@module}`.

      This is useful if the default value is very expensive to calculate or
      generally difficult to setup and teardown again.

      ## Examples
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> #{@module}.pop_lazy(:a, fun)
          {1, #{@module}
          iex> #{@module}.pop_lazy(:b, fun)
          {13, #{@module}
      """
      @spec pop_lazy(key, (() -> value)) :: {value, store}
      def pop_lazy(key, fun) when is_function(fun, 0), do: Mnemonix.pop_lazy(@module, key, fun)

      @doc """
      Puts the given `value` under `key`.

      ## Examples
          iex> #{@module}.put(:b, 2)
          #{@module}
          iex> #{@module}.put(:a, 3)
          #{@module}
      """
      @spec put(key, value) :: store
      def put(key, value), do: Mnemonix.put(@module, key, value)

      @doc """
      Puts the given `value` under `key` unless the entry `key`
      already exists.

      ## Examples
          iex> #{@module}.put_new(:b, 2)
          #{@module}
          iex> #{@module}.put_new(:a, 3)
          #{@module}
      """
      @spec put_new(key, value) :: store
      def put_new(key, value), do: Mnemonix.put_new(@module, key, value)

      @doc """
      Evaluates `fun` and puts the result under `key`
      in `#{@module}` unless `key` is already present.

      This is useful if the value is very expensive to calculate or
      generally difficult to setup and teardown again.

      ## Examples
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   3
          ...> end
          iex> #{@module}.put_new_lazy(:a, fun)
          #{@module}
          iex> #{@module}.put_new_lazy(:b, fun)
          #{@module}
      """
      @spec put_new_lazy(key, (() -> value)) :: store
      def put_new_lazy(key, fun) when is_function(fun, 0), do: Mnemonix.put_new_lazy(@module, key, fun)

      @doc """
      Updates the `key` in `#{@module}` with the given function.
      If the `key` does not exist, inserts the given `initial` value.
      ## Examples
          iex> #{@module}.update(:a, 13, &(&1 * 2))
          #{@module}
          iex> #{@module}.update(:b, 11, &(&1 * 2))
          #{@module}
      """
      @spec update(key, value, (value -> value)) :: store
      def update(key, initial, fun), do: Mnemonix.update(@module, key, initial, fun)

      @doc """
      Updates the `key` with the given function.

      If the `key` does not exist, raises `KeyError`.

      ## Examples
          iex> #{@module}.update!(:a, &(&1 * 2))
          #{@module}
          iex> #{@module}.update!(:b, &(&1 * 2))
          ** (KeyError) key :b not found
      """
      @spec update!(key, (value -> value)) :: store | no_return
      def update!(key, fun), do: Mnemonix.update!(@module, key, fun)
      
    end
  end
  
end