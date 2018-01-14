defmodule Mnemonix.Behaviour.Definition do
  @moduledoc false
  defstruct [:module, :kind, :name, :params, :guards, :body, :docs]

  alias Mnemonix.Behaviour.Definition.Params

  def new(module, kind, name, params, guards, body) do
    %__MODULE__{
      module: module,
      kind: kind,
      name: name,
      params: params,
      guards: guards,
      body: body,
      docs: case Module.get_attribute(module, :doc) do
        {_line, docs} -> docs
        nil -> nil
      end
    }
  end

  def arities(%__MODULE__{} = definition) do
    Params.arities(definition.params)
  end

  def function?(%__MODULE__{} = definition) do
    definition.kind in ~w[def defp]a
  end

  def private?(%__MODULE__{} = definition) do
    definition.kind in ~w[defp defmacrop]a
  end

  def hidden?(%__MODULE__{} = definition) do
    String.starts_with?(Atom.to_string(definition.name), "__")
  end

  def callback?(%__MODULE__{kind: :def} = definition) do
    Enum.any?(arities(definition), fn arity ->
      {definition.name, arity} in definition.module.behaviour_info(:callbacks)
    end)
  end
  def callback?(%__MODULE__{}), do: false

  def args(%__MODULE__{} = definition) do
    definition.params
    |> Params.normalize
    |> Params.strip_matches
    |> Params.strip_defaults
  end

  def docs_with_replacements(%__MODULE__{docs: docs}, find, replace) when is_binary(docs) do
    replacement_name = Inspect.inspect(replace, %Inspect.Opts{})
    find_name = Inspect.inspect(find, %Inspect.Opts{})
    # find all references to this module except where it is being used as a namespace
    find_regex = ~r{#{find_name}(?!\.[A-Z])}
    String.replace(docs, find_regex, replacement_name)
  end

  def docs_with_replacements(%__MODULE__{docs: docs}, _find, _replace), do: docs

end
