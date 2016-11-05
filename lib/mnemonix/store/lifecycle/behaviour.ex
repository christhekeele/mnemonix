defmodule Mnemonix.Store.Lifecycle.Behaviour do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote __MODULE__
      use Mnemonix.Store.Lifecycle.Functions
    end
  end

  alias Mnemonix.Store

  @typep store :: Store.t
  @typep opts  :: Store.opts
  @typep state :: Store.state


  ####
  # REQUIRED
  ##

  @doc """
  Prepares the underlying store type for usage with supplied options.

  Returns internal state the adapter can use to access the underlying
  store to perform operations on data.
  """
  @callback init(opts) ::
    {:ok, state} |
    {:ok, state, timeout | :hibernate} |
    :ignore |
    {:stop, reason :: term}


  ####
  # OPTIONAL
  ##

  @optional_callbacks teardown: 2
  @doc """
  Does any required cleanup when this store terminates.
  """
  @callback teardown(reason, store) :: {:ok, reason} | {:error, reason}
    when reason: :normal | :shutdown | {:shutdown, term} | term

end
