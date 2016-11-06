defmodule Mnemonix.Store.Expiry.Engine do
  @moduledoc false

  use GenServer

  alias Mnemonix.Store

  @type t :: %__MODULE__{default: Store.ttl, timers: Map.t}
  defstruct default: nil, timers: %{}

  @spec start_link(Store.opts) :: GenServer.on_start
  def start_link(opts) do
    GenServer.start_link(__MODULE__, Keyword.get(opts, :ttl, nil), []) # Default genserver opts?
  end

  def init(default_ttl) do
    {:ok, %__MODULE__{default: default_ttl}}
  end

  def expires(%Store{expiry: engine}, key, ttl \\ nil) do
    GenServer.call(engine, {:expires, key, ttl})
  end

  def persist(%Store{expiry: engine}, key) do
    GenServer.call(engine, {:persist, key})
  end

  def handle_call({:expires, key, ttl}, {store, _tag}, state = %__MODULE__{}) do
    with {:ok, state} <- abort(key, state),
         {:ok, state} <- schedule(store, key, ttl, state),
    do: {:reply, :ok, state}
  end

  def handle_call({:persist, key}, _, state = %__MODULE__{}) do
    with {:ok, state} <- abort(key, state) do
      {:reply, :ok, state}
    end
  end

  defp schedule(store, key, nil, state = %__MODULE__{default: ttl}) do
    if ttl do
      schedule(store, key, ttl, state)
    else
      {:ok, store}
    end
  end
  defp schedule(store, key, ttl, state = %__MODULE__{timers: timers}) do
    with {:ok, timer} <- :timer.apply_after(ttl, Mnemonix, :delete, [store, key]) do
      {:ok, %{state | timers: Map.put(timers, key, timer)}}
    end
  end

  defp abort(key, state = %__MODULE__{timers: timers}) do
    case Map.fetch(timers, key) do
      {:ok, timer} -> with {:ok, :cancel} <- :timer.cancel(timer) do
        {:ok, %{state | timers: Map.delete(timers, key)}}
      end
      :error -> {:ok, state}
    end
  end

end
