defmodule Mnemonix.Behaviour do
  @moduledoc false

  defmodule Context do
    @moduledoc false
    defstruct [:module, :source, :docs, :inline, :singleton]
  end

  defmodule Definition do
    @moduledoc false
    defstruct [:module, :kind, :name, :params, :guards, :body, :docs]

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
      Enum.any?(arity(definition), fn arity ->
        {definition.name, arity} in definition.module.behaviour_info(:callbacks)
      end)
    end
    def callback?(%__MODULE__{}), do: false

    def arity(%__MODULE__{} = definition) do
      {arity, defaults} = Enum.reduce(definition.params, {0, 0}, fn
        {:\\, _, [_arg, _default]}, {arity, defaults} ->
          {arity, defaults + 1}
        _ast, {arity, defaults} ->
          {arity + 1, defaults}
      end)
      Range.new(arity, arity + defaults)
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

  def __on_definition__(env, kind, name, params, guards, body) do
    definition = Definition.new(env.module, kind, name, params, guards, body)
    Module.put_attribute(env.module, :__definitions__, definition)
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      @doc false
      def __definitions__, do: @__definitions__
    end
  end

  defmacro __using__(opts \\ []) do
    code = Keyword.get(opts, :do)
    source = Keyword.get(opts, :source, __CALLER__.module)

    quote location: :keep do
      Module.register_attribute(__MODULE__, :__definitions__, accumulate: true)

      @on_definition Mnemonix.Behaviour
      @before_compile Mnemonix.Behaviour

      defmacro __using__(opts \\ []) do
        docs = Keyword.get(opts, :docs, true)
        inline = Keyword.get(opts, :inline, false)
        source = Keyword.get(opts, :source, unquote(source))

        {singleton, opts} =
          Mnemonix.Singleton.Behaviour.establish_singleton(__CALLER__.module, opts)

        defaults = source.__definitions__
        |> Enum.filter(fn definition ->
          Definition.function?(definition) and not Definition.hidden?(definition)
        end)
        |> Enum.map(fn definition ->
            %Mnemonix.Behaviour.Definition{
              module: module,
              kind: kind,
              name: name,
              params: params,
              guards: guards,
              body: body,
              docs: doc
            } = definition

            info = %{
              module: __MODULE__,
              source: source,
              kind: kind,
              docs: docs,
              inline: inline,
              callback: Mnemonix.Behaviour.Definition.callback?(definition),
              singleton: singleton,
            }

            doc = Definition.docs_with_replacements(definition, source, __CALLER__.module)

            Mnemonix.Behaviour.compose_default(info, doc, name, params, guards, body)
          end)

        [
          quote(location: :keep, do: @behaviour(unquote(__MODULE__))),
          defaults,
          quote(location: :keep, do: defoverridable(unquote(__MODULE__))),
          unquote(code)
        ]
        |> List.flatten()
        |> Enum.filter(&(&1))
      end
    end
  end

  # If we are inlining, we may need any and all functions, private ones included
  def compose_default(%{inline: true} = info, doc, name, params, guards, body) do
    compose_definition(info, doc, name, params, guards, body)
  end

  # Otherwise we are only interested in public functions
  def compose_default(%{kind: :def} = info, doc, name, params, guards, _body) do
    %{module: module, singleton: singleton, callback: callback} = info

    params =
      params
      |> normalize_params
      |> Macro.prewalk(fn
           {:=, _, [{name, _, context} = arg1, arg2]} ->
             if is_atom(name) and (is_atom(context) or context == nil) do
               arg1
             else
               arg2
             end

           ast ->
             ast
         end)

    params = if singleton, do: tl(params), else: params

    args =
      params
      |> Macro.prewalk(fn
           {:\\, _, [arg, _default]} -> arg
           ast -> ast
         end)

    delegate = [do: compose_delegate(info, name, args)]
    definition = compose_definition(info, doc, name, params, guards, delegate)

    [
      if(callback, do: compose_module_attribute(:impl, module)),
      definition
    ]
  end

  # Throw away anything else
  def compose_default(_info, _doc, _name, _params, _guards, _body), do: nil

  def normalize_params(params) do
    params
    |> Enum.with_index(1)
    |> Enum.map(&normalize_param/1)
  end

  def normalize_param({{:\\, meta, [param, default]}, i}),
    do: {{:\\, meta, [normalize_param({param, i}), normalize_param({default, i})]}, i}

  def normalize_param({{:_, meta, context}, i}), do: {String.to_atom("arg#{i}"), meta, context}

  def normalize_param({{name, meta, context}, _})
      when is_atom(name) and (is_atom(context) or context == nil) do
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

  def normalize_param({{two, tuple}, i}) do
    {normalize_param({two, i}), normalize_param({tuple, i})}
  end

  def normalize_param({literal, _}), do: literal

  defp compose_delegate(%{source: source, singleton: singleton}, name, args) do
    args = if singleton, do: [singleton | args], else: args
    compose_application(source, name, args)
  end

  defp compose_definition(%{kind: :def} = info, doc, name, params, guards, body) do
    [
      compose_docs(info, doc),
      compose_function(:def, name, params, guards, body)
    ]
  end

  defp compose_definition(%{kind: :defp}, _doc, name, params, guards, body) do
    compose_function(:defp, name, params, guards, body)
  end

  defp compose_docs(%{docs: false} = info, _doc), do: compose_docs(info, false)

  defp compose_docs(_info, doc) when is_binary(doc) do
    compose_module_attribute(:doc, doc)
  end

  defp compose_docs(_info, _doc) do
    compose_module_attribute(:doc, false)
  end

  defp compose_function(:def, name, params, guards, body) do
    definition = compose_definition(name, params, guards)

    quote location: :keep do
      Kernel.def(unquote(definition), unquote(body))
    end
  end

  defp compose_function(:defp, name, params, guards, body) do
    definition = compose_definition(name, params, guards)

    quote location: :keep do
      Kernel.defp(unquote(definition), unquote(body))
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
