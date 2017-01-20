defmodule Mnemonix.Store do
  @moduledoc false

  @typedoc """
  Container for `Mnemonix.Store.Server` state.
  """
  @type t :: %__MODULE__{
    impl: Mnemonix.Store.Behaviour.t,
    opts: Mnemonix.Store.Server.options,
    state: state :: term,
    expiry: :native | pid
  }
  @enforce_keys [:impl, :opts, :state]
  defstruct [:impl, :opts, :state, expiry: :native]

  @doc false
  @spec new(Mnemonix.Store.Behaviour.t, Mnemonix.Store.Server.options, state :: term) :: t
  def new(impl, opts, state) do
    %__MODULE__{impl: impl, opts: opts, state: state}
  end

end
