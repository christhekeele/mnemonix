defmodule Mnemonix.Singleton do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      alias Mnemonix.Store

      @store unquote(__CALLER__.module |> Inspect.inspect(%Inspect.Opts{}))

      def singleton do
        unquote(__CALLER__.module)
      end

      @typep store   :: Atom.t
      @typep adapter :: Store.adapter
      @typep opts    :: Store.opts
      @typep key     :: Store.key
      @typep value   :: Store.value

      @doc """
      Starts a new `Mnemonix.Store` using `adapter`.

      If you wish to pass options to `GenServer.start_link/3`,
      use `start_link/2`.

      The returned `t:GenServer.server/0` reference can be used in
      the `Mnemonix` API.

      ## Examples

        iex> {:ok, store} = Mnemonix.Store.start_link(Mnemonix.Map.Store)
        iex> Mnemonix.put(store, :foo, :bar)
        iex> Mnemonix.get(store, :foo)
        :bar

        iex> {:ok, store} = Mnemonix.Store.start_link({Mnemonix.Map.Store, initial: %{foo: :bar}})
        iex> Mnemonix.get(store, :foo)
        :bar
      """
      @spec start_link(adapter)         :: GenServer.on_start
      @spec start_link({adapter, opts}) :: GenServer.on_start
      def start_link(init) do
        Store.start_link(init, [])
      end

      @doc """
      Starts a new `Mnemonix.Store` using `adapter` with `opts`.

      The returned `t:GenServer.server/0` reference can be used in
      the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = Mnemonix.Store.start_link(Mnemonix.Map.Store, name: Cache)
          iex> Mnemonix.put(Cache, :foo, :bar)
          iex> Mnemonix.get(Cache, :foo)
          :bar

          iex> {:ok, store} = Mnemonix.Store.start_link({Mnemonix.Map.Store, initial: %{foo: :bar}}, name: Cache)
          iex> Mnemonix.get(Cache, :foo)
          :bar
      """
      def start_link(init, opts)

      @spec start_link({adapter, opts}, GenServer.options) :: GenServer.on_start
      def start_link(adapter, opts) when not is_tuple adapter do
        Store.start_link(__MODULE__, {adapter, []}, opts)
      end

      @spec start_link(adapter, GenServer.options) :: GenServer.on_start
      def start_link(init, opts) do
        Store.start_link(__MODULE__, init, opts)
      end

      ####
      # CORE
      ##

      @doc """
      Deletes the entries in `#{@store}` for a specific `key`.

      If the `key` does not exist, the contents of `#{@store}`
      will be unaffected.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.get(:a)
          1
          iex> #{@store}.delete(:a)
          iex> #{@store}.get(:a)
          nil
      """
      @spec delete(key) :: store | no_return
      def delete(key) do
        Mnemonix.delete(@store, key)
      end

      # TODO: expiry
      # @doc """
      # Sets the entry under `key` to expire in `ttl` seconds.
      #
      # If the `key` does not exist, the contents of `#{@store}`
      will be unaffected.
      #
      # ## Examples

      #     iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
      #     iex> #{@store}.expires(:a, 100)
      #     iex> :timer.sleep(101)
      #     iex> #{@store}.get(:a)
      #     nil
      # """
      # @spec expires(key, ttl) :: store | no_return
      # def expires(key, ttl) do
      #   Mnemonix.expires(@store, key, ttl)
      # end

      @doc """
      Fetches the value for a specific `key` and returns it in a tuple.

      If the `key` does not exist, returns `:error`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.fetch(:a)
          {:ok, 1}
          iex> #{@store}.fetch(:b)
          :error
      """
      @spec fetch(key) :: {:ok, value} | :error | no_return
      def fetch(key) do
        Mnemonix.fetch(@store, key)
      end

      @doc """
      Puts the given `value` under `key`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.get(:b)
          nil
          iex> #{@store}.put(:b, 2)
          iex> #{@store}.get(:b)
          2
      """
      @spec put(key, value) :: store | no_return
      def put(key, value) do
        Mnemonix.put(@store, key, value)
      end

      ####
      # MAP FUNCTIONS
      ##

      @doc """
      Fetches the value for specific `key`.

      If `key` does not exist, a `KeyError` is raised.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.fetch!(:a)
          1
          iex> #{@store}.fetch!(:b)
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
      """
      @spec fetch!(key) :: {:ok, value} | :error | no_return
      def fetch!(key) do
        Mnemonix.fetch!(@store, key)
      end

      @doc """
      Gets the value for a specific `key`.

      If `key` does not exist, returns `nil`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.get(:a)
          1
          iex> #{@store}.get(:b)
          nil
      """
      @spec get(key) :: value | no_return
      def get(key) do
        Mnemonix.get(@store, key)
      end

      @doc """
      Gets the value for a specific `key` with `default`.

      If `key` does not exist, returns `default`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.get(:a, 2)
          1
          iex> #{@store}.get(:b, 2)
          2
      """
      @spec get(key, value) :: value | no_return
      def get(key, default) do
        Mnemonix.get(@store, key, default)
      end

      @doc """
      Gets the value from `key` and updates it, all in one pass.

      This `fun` argument receives the value of `key` (or `nil` if `key`
      is not present) and must return a two-element tuple: the "get" value
      (the retrieved value, which can be operated on before being returned)
      and the new value to be stored under `key`. The `fun` may also
      return `:pop`, implying the current value shall be removed
      from `#{@store}` and returned.

      The returned value is a tuple with the "get" value returned by
      `fun` and a reference to `#{@store}` with the updated value under `key`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store}} = #{@store}.get_and_update(:a, fn current ->
          ...>   {current, "new value!"}
          ...> end)
          iex> value
          1
          iex> #{@store}.get(:a)
          "new value!"

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store}} = #{@store}.get_and_update(:b, fn current ->
          ...>   {current, "new value!"}
          ...> end)
          iex> value
          nil
          iex> #{@store}.get(:b)
          "new value!"

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store}} = #{@store}.get_and_update(:a, fn _ -> :pop end)
          iex> value
          1
          iex> #{@store}.get(:a)
          nil

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store}} = #{@store}.get_and_update(:b, fn _ -> :pop end)
          iex> value
          nil
          iex> #{@store}.get(:b)
          nil
      """
      @spec get_and_update(key, (value -> {get, value} | :pop))
        :: {get, store} | no_return when get: term
      def get_and_update(key, fun) do
        Mnemonix.get_and_update(@store, key, fun)
      end

      @doc """
      Gets the value from `key` and updates it. Raises if there is no `key`.

      This `fun` argument receives the value of `key` and must return a
      two-element tuple: the "get" value (the retrieved value, which can be
      operated on before being returned) and the new value to be stored under
      `key`.

      The returned value is a tuple with the "get" value returned by `fun` and a
      a reference to `#{@store}` with the updated value under `key`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store} = #{@store}.get_and_update!(:a, fn current ->
          ...>   {current, "new value!"}
          ...> end)
          iex> value
          1
          iex> #{@store}.get(:a)
          "new value!"

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store} = #{@store}.get_and_update!(:b, fn current ->
          ...>   {current, "new value!"}
          ...> end)
          ** (KeyError) key :b not found in: Mnemonix.Map.Store

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store} = #{@store}.get_and_update!(:a, fn _ -> :pop end)
          iex> value
          1
          iex> #{@store}.get(:a)
          nil

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store} = #{@store}.get_and_update!(:b, fn _ -> :pop end)
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
      """
      @spec get_and_update!(key, (value -> {get, value}))
        :: {get, store} | no_return when get: term
      def get_and_update!(key, fun) do
        Mnemonix.get_and_update!(@store, key, fun)
      end

      @doc """
      Gets the value for a specific `key`.

      If `key` does not exist, lazily evaluates `fun` and returns its result.

      This is useful if the default value is very expensive to calculate or
      generally difficult to setup and teardown again.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> #{@store}.get_lazy(:a, fun)
          1
          iex> #{@store}.get_lazy(:b, fun)
          13
      """
      @spec get_lazy(key, (() -> value)) :: value | no_return
      def get_lazy(key, fun) when is_function(fun, 0) do
        Mnemonix.get_lazy(@store, key, fun)
      end

      @doc """
      Returns whether a given `key` exists in `#{@store}`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.has_key?(:a)
          true
          iex> #{@store}.has_key?(:b)
          false
      """
      @spec has_key?(key) :: boolean
      def has_key?(key) do
        Mnemonix.has_key?(@store, key)
      end

      @doc """
      Returns and removes the value associated with `key` in `#{@store}`.

      If no value is associated with the `key`, `nil` is returned.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store} = #{@store}.pop(:a)
          iex> value
          1
          iex> #{@store}.get(:a)
          nil
          iex> {value, ^#{@store} = #{@store}.pop(store, :b)
          iex> value
          nil
      """
      @spec pop(key) :: {value, store}
      def pop(key) do
        Mnemonix.pop(@store, key)
      end


      @doc """
      Returns and removes the value associated with `key` in `#{@store}`
      with `default`.

      If no value is associated with the `key` but `default` is given,
      that will be returned instead without touching the store.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> {value, ^#{@store} = #{@store}.pop(:a)
          iex> value
          nil
          iex> {value, ^#{@store} = #{@store}.pop(:b, 2)
          iex> value
          2
      """
      @spec pop(key, term) :: {value, store}
      def pop(key, default) do
        Mnemonix.pop(@store, key, default)
      end

      @doc """
      Lazily returns and removes the value associated with `key` in `#{@store}`.

      This is useful if the default value is very expensive to calculate or
      generally difficult to setup and teardown again.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> {value, ^#{@store} = #{@store}.pop_lazy(:a, fun)
          iex> value
          1
          iex> {value, ^#{@store} = #{@store}.pop_lazy(:b, fun)
          iex> value
          13
      """
      @spec pop_lazy(key, (() -> value)) :: {value, store}
      def pop_lazy(key, fun) when is_function(fun, 0) do
        Mnemonix.pop_lazy(@store, key, fun)
      end

      @doc """
      Puts the given `value` under `key` unless the entry `key`
      already exists.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.put_new(:b, 2)
          iex> #{@store}.get(:b)
          2
          iex> #{@store}.put_new(:b, 3)
          iex> #{@store}.get(:b)
          2
      """
      @spec put_new(key, value) :: store
      def put_new(key, value) do
        Mnemonix.put_new(@store, key, value)
      end

      @doc """
      Evaluates `fun` and puts the result under `key`
      in `#{@store}` unless `key` is already present.

      This is useful if the value is very expensive to calculate or
      generally difficult to setup and teardown again.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> fun = fn ->
          ...>   # some expensive operation here
          ...>   13
          ...> end
          iex> #{@store}.put_new_lazy(:b, fun)
          iex> #{@store}.get(:b)
          13
          iex> #{@store}.put_new_lazy(:a, fun)
          iex> #{@store}.get(:a)
          1
      """
      @spec put_new_lazy(key, (() -> value)) :: store | no_return
      def put_new_lazy(key, fun) when is_function(fun, 0) do
        Mnemonix.put_new_lazy(@store, key, fun)
      end

      # TODO:
      # split(keys)
      # Takes all entries corresponding to the given keys
      # and extracts them into a map

      # TODO:
      # take(keys)
      # Takes all entries corresponding to the given keys
      # and returns them in a map

      @doc """
      Updates the `key` in `#{@store}` with the given function.

      If the `key` does not exist, inserts the given `initial` value.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.update(:a, 13, &(&1 * 2))
          iex> #{@store}.get(:a)
          2
          iex> #{@store}.update(:b, 13, &(&1 * 2))
          iex> #{@store}.get(:b)
          13
      """
      @spec update(key, value, (value -> value)) :: store | no_return
      def update(key, initial, fun) do
        Mnemonix.update(@store, key, initial, fun)
      end

      @doc """
      Updates the `key` with the given function.

      If the `key` does not exist, raises `KeyError`.

      ## Examples

          iex> #{@store}.start_link({Mnemonix.Map.Store, initial: %{a: 1}})
          iex> #{@store}.update!(:a, &(&1 * 2))
          iex> #{@store}.get(:a)
          2
          iex> #{@store}.update!(:b, &(&1 * 2))
          ** (KeyError) key :b not found in: Mnemonix.Map.Store
      """
      @spec update!(key, (value -> value)) :: store | no_return
      def update!(key, fun) do
        Mnemonix.update!(@store, key, fun)
      end

    end
  end

end
