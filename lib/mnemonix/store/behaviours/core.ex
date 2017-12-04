defmodule Mnemonix.Store.Behaviours.Core do
  @moduledoc false

  use Mnemonix.Behaviour do
    quote do
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

  @callback setup(Mnemonix.Store.options()) ::
              {:ok, state :: term} | :ignore | {:stop, reason :: term}
  # @doc false
  # @spec setup(Mnemonix.Store.options)
  #   :: {:ok, state :: term} | :ignore | {:stop, reason :: term}
  # def setup(options), do: {:ok, options}

  @callback start_link() :: {:ok, Mnemonix.store()} | no_return
  @callback start_link(options :: Keyword.t()) :: {:ok, Mnemonix.store()} | no_return

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
      start: {Mnemonix.Store.Server, :start_link, [__MODULE__, options]},
      restart: restart,
      shutdown: shutdown,
      type: :worker
    }
  end

  @callback setup_initial(Mnemonix.Store.t()) :: {:ok, Mnemonix.store()} | no_return
  def setup_initial(store = %Mnemonix.Store{impl: impl, opts: opts}) do
    {:ok, store} =
      opts
      |> Keyword.get(:initial, %{})
      |> Enum.map(fn {key, value} ->
           {impl.serialize_key(store, key), impl.serialize_value(store, value)}
         end)
      |> Enum.reduce({:ok, store}, fn {key, value}, {:ok, store} ->
           impl.put(store, key, value)
         end)

    {:ok, store}
  end

  @callback teardown(reason, Mnemonix.Store.t()) :: {:ok, reason} | {:error, reason}
            when reason: :normal | :shutdown | {:shutdown, term} | term
  @doc false
  @spec teardown(reason, Mnemonix.Store.t()) :: {:ok, reason} | {:error, reason}
        when reason: :normal | :shutdown | {:shutdown, term} | term
  def teardown(reason, _store) do
    {:ok, reason}
  end
end
