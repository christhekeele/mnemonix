defmodule Mnemonix.Behaviour do
  @moduledoc """
  Creates a behaviour that carries its own default implementation.

  When used, all functions defined on itself are given to the using module.

  Opts info.
  """ && false

  def __on_definition__(env, kind, name, params, guards, body) do
    doc = Module.get_attribute(env.module, :doc)
    Module.put_attribute(env.module, :__functions__, {doc, kind, name, params, guards, body})
    callback = Module.get_attribute(env.module, :callback)
    case {kind, callback} do
      {_kind, []} -> nil
      {:def, [callback | _]} -> Module.put_attribute(env.module, :__callbacks__, {callback_signature(env.module, callback)})
      _ -> nil
    end
  end

  defp callback_signature(module, {:callback, definition, _module_info}) do
    callback_signature(module, definition)
  end
  defp callback_signature(module, {:when, _, [node, _names]}) do
    callback_signature(module, node)
  end
  defp callback_signature(module, {:::, _, [{name, _, nil}, _return]}) do
    {module, name, 0}
  end
  defp callback_signature(module, {:::, _, [{name, _, args}, _return]}) do
    {module, name, length(args)}
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      @doc false
      def __functions__, do: @__functions__
      def __callbacks__, do: @__callbacks__
    end
  end

  defmacro __using__(opts \\ []) do
    code = Keyword.get(opts, :do)
    source = Keyword.get(opts, :source, __CALLER__.module)
    quote location: :keep do

      Module.register_attribute(__MODULE__, :__functions__, accumulate: true)
      Module.register_attribute(__MODULE__, :__callbacks__, accumulate: true)

      @on_definition Mnemonix.Behaviour
      @before_compile Mnemonix.Behaviour

      defmacro __using__(opts \\ []) do
        docs = Keyword.get(opts, :docs, true)
        inline = Keyword.get(opts, :inline, false)
        source = Keyword.get(opts, :source, unquote(source))

        {singleton, opts} = Mnemonix.Singleton.Behaviour.establish_singleton(__CALLER__.module, opts)

        defaults = for {doc, kind, name, params, guards, body} when kind in ~w[def defp]a <- source.__functions__ do
          if String.starts_with?(Atom.to_string(name), "__") do
            nil
          else
            callback = {source, name, length(params)} in source.__callbacks__
            if callback, do: IO.inspect {source, name, length(params)}
            info = %{module: __MODULE__, source: source, kind: kind, docs: docs, inline: inline, callback: callback, singleton: singleton}
            Mnemonix.Behaviour.compose_default(info, doc, name, params, guards, body)
          end
        end

        [
          quote(do: @behaviour unquote(__MODULE__)),
          defaults,
          quote(do: defoverridable unquote(__MODULE__)),
          unquote(code),
        ] |> List.flatten |> Enum.filter(&(&1))

      end
    end
  end

  # If we are inlining, we may need any and all functions, private ones included
  def compose_default(%{inline: true} = info, doc, name, params, guards, body) do
    compose_definition(info, doc, name, params, guards, body)
  end

  # Otherwise we are only interested in public functions
  def compose_default(%{kind: :def, module: module, singleton: singleton, callback: callback} = info, doc, name, params, guards, _body) do
    params = normalize_params(params)
    |> Macro.prewalk(fn
      {:=, _, [{name, _, context} = arg1, arg2]} ->
        if is_atom(name) and (is_atom(context) or context == nil) do
          arg1
        else
          arg2
        end
      ast -> ast
    end)
    params = if singleton, do: tl(params), else: params
    args = params
    |> Macro.prewalk(fn
      {:\\, _, [arg, _default]} -> arg
      ast -> ast
    end)
    delegate = [do: compose_delegate(info, name, args)]
    definition = compose_definition(info, doc, name, params, guards, delegate)
    [
      (if callback, do: compose_module_attribute(:impl, module)),
      definition,
    ]
  end

  # Throw away anything else
  def compose_default(_info, _doc, _name, _params, _guards, _body), do: nil

  def normalize_params(params) do
    params
    |> Enum.with_index(1)
    |> Enum.map(&normalize_param/1)
  end

  def normalize_param({{:\\, meta, [param, default]}, i}), do: {{:\\, meta, [normalize_param({param, i}), normalize_param({default, i})]}, i}
  def normalize_param({{:_, meta, context}, i}), do: {String.to_atom("arg#{i}"), meta, context}
  def normalize_param({{name, meta, context}, _}) when is_atom(name) and (is_atom(context) or context == nil) do
    string = Atom.to_string(name)
    if String.starts_with?(string, "_") do
      {String.to_atom(String.trim_leading(string, "_")), meta, context}
    else
      {name, meta, context}
    end
  end
  def normalize_param({{call, meta, args}, i}) when is_list(args) do
    params = Enum.map(args, fn param -> normalize_param({param, i}) end)
    {call, meta, params}
  end
  def normalize_param({{call, meta, args}, i}) when is_list(args) do
    params = Enum.map(args, fn param -> normalize_param({param, i}) end)
    {call, meta, params}
  end
  def normalize_param({{two, tuple}, i}), do: {normalize_param({two, i}), normalize_param({tuple, i})}
  def normalize_param({literal, _}), do: literal

  defp compose_delegate(%{source: source, singleton: singleton}, name, args) do
    args = if singleton, do: [singleton | args], else: args
    compose_application(source, name, args)
  end

  defp compose_definition(info = %{kind: :def}, doc, name, params, guards, body) do
    [
      compose_docs(info, doc),
      compose_function(:def, name, params, guards, body),
    ]
  end

  defp compose_definition(%{kind: :defp}, _doc, name, params, guards, body) do
    compose_function(:defp, name, params, guards, body)
  end

  defp compose_docs(%{docs: false} = info, _doc), do: compose_docs(info, false)
  defp compose_docs(_info, {_, doc}) when is_binary(doc) do
    compose_module_attribute(:doc, doc)
  end
  defp compose_docs(_info, _doc) do
    compose_module_attribute(:doc, false)
  end

  defp compose_function(:def, name, params, guards, body) do
    definition = compose_definition(name, params, guards)
    quote location: :keep do
      Kernel.def unquote(definition), unquote(body)
    end
  end

  defp compose_function(:defp, name, params, guards, body) do
    definition = compose_definition(name, params, guards)
    quote location: :keep do
      Kernel.defp unquote(definition), unquote(body)
    end
  end

  defp compose_definition(name, params, []) do
    compose_call(name, params)
  end
  defp compose_definition(name, params, guards) do
    Enum.reduce(guards, compose_call(name, params), fn guard, node ->
      {:when, [], [node, guard]}
    end)
  end

  defp compose_call(name, params) do
    {name, [], params}
  end

  defp compose_module_attribute(attribute, value) do
    {:@, [], [
      {attribute, [], [value]}
    ]}
  end

  defp compose_application(module, function, args) do
    {:apply, [], [module, function, args]}
  end

end
