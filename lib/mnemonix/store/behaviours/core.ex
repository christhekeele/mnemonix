defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  use Mnemonix.Behaviour do
    quote location: :keep do
      @impl unquote(__MODULE__)
      def start_link() do
        Mnemonix.Store.Server.start_link(__MODULE__, [])
      end

      @impl unquote(__MODULE__)
      def start_link(opts) do
        Mnemonix.Store.Server.start_link(__MODULE__, opts)
      end
    end
  end

  alias Mnemonix.Store

  @callback child_spec() :: Supervisor.child_spec()
  @doc false
  @spec child_spec() :: Supervisor.child_spec()
  def child_spec(), do: child_spec([])

  @callback child_spec(options :: Keyword.t()) :: Supervisor.child_spec()
  @doc false
  @spec child_spec(options :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(options) do
    {restart, options} = Keyword.pop(options, :restart, :permanent)
    {shutdown, options} = Keyword.pop(options, :shutdown, 5000)

    %{
      id: make_ref(),
      start: {Store.Server, :start_link, [__MODULE__, options]},
      restart: restart,
      shutdown: shutdown,
      type: :worker,
    }
  end

  @callback start_link() :: {:ok, Mnemonix.store()} | no_return
  @callback start_link(options :: Keyword.t()) :: {:ok, Mnemonix.store()} | no_return

  @callback setup(Store.options()) ::
              {:ok, state :: term} | :ignore | {:stop, reason :: term}
  # @doc false
  # @spec setup(Store.options) ::
  #         {:ok, Store.t()} | :ignore | {:stop, reason :: term}
  # def setup(options), do: {:ok, Mnemonix.Store}

  @callback setup_initial(Store.t()) ::
              {:ok, Store.t()} | :ignore | {:stop, reason :: term}
  @doc false
  @spec setup_initial(Store.t()) ::
              {:ok, Store.t()} | :ignore | {:stop, reason :: term}
  def setup_initial(%Store{} = store) do
    %Store{impl: impl, opts: opts} = store

    opts
    |> Keyword.get(:initial, %{})
    |> Enum.map(fn {key, value} ->
         {impl.serialize_key(store, key), impl.serialize_value(store, value)}
       end)
    |> Enum.reduce({:ok, store}, fn {key, value}, {:ok, store} ->
         impl.put(store, key, value)
       end)
  end

  @callback teardown(reason, Store.t()) :: {:ok, reason} | {:error, reason}
            when reason: :normal | :shutdown | {:shutdown, term} | term
  @doc false
  @spec teardown(reason, Store.t()) :: {:ok, reason} | {:error, reason}
        when reason: :normal | :shutdown | {:shutdown, term} | term
  def teardown(reason, _store) do
    {:ok, reason}
  end
end
