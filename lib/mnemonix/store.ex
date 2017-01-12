defmodule Mnemonix.Store do
  @moduledoc """
  Normalizes access to different key-value stores behind a `GenServer`.

  Once a store [has been started](Mnemonix.Store.Server#start_link/1), you can use `Mnemonix`
  methods to manipulate it:

      iex> Mnemonix.Store.Server.start_link(Mnemonix.Map.Store, name: Store)
      iex> Mnemonix.put(Store, :foo, "bar")
      iex> Mnemonix.fetch(Store, :foo)
      {:ok, "bar"}
      iex> Mnemonix.delete(Store, :foo)
      iex> Mnemonix.fetch(Store, :foo)
      :error
  """

  @typedoc """
  A module implementing `Mnemonix.Store.Behaviour`.
  """
  @type impl :: Module.t

  @typedoc """
  Options supplied to `c:Mnemonix.Store.Lifecycle.Behaviour.setup/1` to initialize
  the `t:impl/0`.
  """
  @type opts :: Keyword.t

  @typedoc """
  Internal state specific to the `t:impl/0`.
  """
  @type state :: term

  @typedoc """
  Container for `t:impl/0`, `t:opts/0`, and `t:state/0`.
  """
  @type t :: %__MODULE__{impl: impl, opts: opts, state: state, expiry: :native | pid}
  @enforce_keys [:impl]
  defstruct impl: nil, opts: [], state: nil, expiry: :native

  @doc false
  @spec new(impl, opts, state) :: t
  def new(impl, opts, state) do
    %__MODULE__{impl: impl, opts: opts, state: state}
  end

  @typedoc """
  Adapter and optional initialization options for `start_link/1`.
  """
  @type init :: impl | {impl, opts}

  @typedoc """
  Keys allowed in Mnemonix entries.
  """
  @type key :: term

  @typedoc """
  Values allowed in Mnemonix entries.
  """
  @type value :: term

  @typedoc """
  The number of milliseconds an entry will be allowed to exist.
  """
  @type ttl :: non_neg_integer | nil

  @typedoc """
  The return value of a bump operation.
  """
  @type bump_op :: :ok | {:error, :no_integer}

end
