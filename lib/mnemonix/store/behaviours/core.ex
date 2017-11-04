defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  @callback start_link()
    :: GenServer.on_start

  @callback start_link(Mnemonix.Supervisor.options)
    :: GenServer.on_start

  @callback start_link(Mnemonix.Supervisor.options, GenServer.options)
    :: GenServer.on_start

  @callback setup(Mnemonix.Store.options)
    :: {:ok, state :: term} | :ignore | {:stop, reason :: term}

  @callback setup_initial(Mnemonix.Store.t)
    :: {:ok, Mnemonix.store} | no_return

  @callback teardown(reason, Mnemonix.Store.t)
    :: {:ok, reason} | {:error, reason}
      when reason: :normal | :shutdown | {:shutdown, term} | term

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour unquote __MODULE__

      @store __MODULE__ |> Inspect.inspect(%Inspect.Opts{})

      @doc """
      Starts a new store using the `#{@store}` module with `options`.

      The `options` are the same as described in `Mnemonix.Features.Supervision.start_link/2`.
      The `:store` options are used in `setup/1` to start the store;
      the `:server` options are passed directly to `GenServer.start_link/2`.

      The returned `t:GenServer.server/0` reference can be used as the primary
      argument to the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = #{@store}.start_link()
          iex> Mnemonix.put(store, "foo", "bar")
          iex> Mnemonix.get(store, "foo")
          "bar"

          iex> {:ok, _store} = #{@store}.start_link(server: [name: My.#{@store}])
          iex> Mnemonix.put(My.#{@store}, "foo", "bar")
          iex> Mnemonix.get(My.#{@store}, "foo")
          "bar"
      """
      @impl unquote __MODULE__
      @spec start_link()                            :: GenServer.on_start
      @spec start_link(Mnemonix.Supervisor.options) :: GenServer.on_start
      def start_link(options \\ []) do
        Mnemonix.start_link(__MODULE__, options)
      end

      @doc """
      Starts a new store using `#{@store}` with `store` and `server` options.

      The options are the same as described in `Mnemonix.start_link/2`.
      The `store` options are used in `setup/1` to start the store;
      the `server` options are passed directly to `GenServer.start_link/2`.

      The returned `t:GenServer.server/0` reference can be used as the primary
      argument to the `Mnemonix` API.

      ## Examples

          iex> {:ok, store} = #{@store}.start_link([], [])
          iex> Mnemonix.put(store, "foo", "bar")
          iex> Mnemonix.get(store, "foo")
          "bar"

          iex> {:ok, _store} = #{@store}.start_link([], [name: My.#{@store}])
          iex> Mnemonix.put(My.#{@store}, "foo", "bar")
          iex> Mnemonix.get(My.#{@store}, "foo")
          "bar"
      """
      @impl unquote __MODULE__
      @spec start_link(Mnemonix.Supervisor.options, GenServer.options) :: GenServer.on_start
      def start_link(store, server) do
        Mnemonix.Store.Server.start_link(__MODULE__, store, server)
      end

      @impl unquote __MODULE__
      def setup_initial(store = %Mnemonix.Store{impl: impl, opts: opts}) do
        opts
        |> Keyword.get(:initial, %{})
        |> Enum.reduce({:ok, store}, fn {key, value}, {:ok, store} ->
          impl.put(store, impl.serialize_key(store, key), impl.serialize_value(store, value))
        end)
      end

      @impl unquote __MODULE__
      def teardown(reason, _store) do
        {:ok, reason}
      end
    end
  end

end
