defmodule Mnemonix.Store.Server.Spec do
  @moduledoc """
  Utilities for building standardized representations of `Mnemonix.Store.Server`s for `Supervisor`s.
  """

  @keys ~w[name impl opts]a
  @enforce_keys @keys
  defstruct @keys

  def new({name, opts}) when is_list opts do
    new {name, Enum.into(opts, %{})}
  end
  def new({name, opts}) when is_map opts do
    %__MODULE__{
      name: name,
      impl: Map.get(opts, :impl, Keyword.get(default_opts(), :impl)),
      opts: Map.get(opts, :opts, Keyword.get(default_opts(), :opts)),
    }
  end
  def new({otp_app, name}) when is_atom otp_app and is_atom name do
    new {name, Application.get_env(otp_app, name, default_opts())}
  end
  def new(opts) do
    new {nil, opts}
  end

  def worker(%__MODULE__{name: name,  impl: impl, opts: opts}) do
    gen_server_opts = if name do
      [name: name]
    else
      []
    end
    Supervisor.Spec.worker(Mnemonix.Store.Server, [{impl, opts}, gen_server_opts])
  end

  def default_opts do
    [impl: Mnemonix.Map.Store, opts: []]
  end

end
