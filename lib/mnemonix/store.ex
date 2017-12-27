defmodule Mnemonix.Store do
  @moduledoc false

  @type option :: {atom, term}
  @type options :: [option]

  @typedoc """
  Container for store state.
  """
  @type t :: %__MODULE__{
          impl: Mnemonix.Store.Behaviour.t(),
          opts: options,
          state: state :: term,
          expiry: :ets.tab() | :native,
        }
  @enforce_keys [:impl, :opts, :state]
  defstruct [:impl, :opts, :state, expiry: :native]

  @doc false
  @spec new(Mnemonix.Store.Behaviour.t(), options, state :: term) :: t
  def new(impl, opts, state) do
    %__MODULE__{impl: impl, opts: opts, state: state}
  end
end
