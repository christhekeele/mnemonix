defmodule Mnemonix.Store.Spec do

  @keys ~w[name impl opts]a
  @enforce_keys @keys
  defstruct @keys

  def new({otp_app, name}) when is_atom otp_app and is_atom name do
    new {name, Application.get_env(otp_app, name, default_opts)}
  end
  def new({name, opts}) do
    %__MODULE__{
      name: name,
      impl: Map.get(opts, :impl, Map.fetch(default_opts, :impl)),
      opts: Map.get(opts, :opts, Map.fetch(default_opts, :opts))},
    }
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
