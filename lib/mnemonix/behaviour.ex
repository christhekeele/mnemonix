defmodule Mnemonix.Behaviour do
  @moduledoc false

  alias Mnemonix.Behaviour.Definition

  defmodule Context do
    @moduledoc false
    defstruct [:caller, :module, :source, :docs, :inline, :singleton, :only, :except]

    def implement?(%__MODULE__{only: :all} = context, function, arity) do
      {function, arity} not in context.except
    end

    def implement?(%__MODULE__{} = context, function, arity) do
      {function, arity} in context.only and implement?(%{context | only: :all}, function, arity)
    end
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
        alias Mnemonix.Behaviour.{Context, Definition}

        source = Keyword.get(opts, :source, unquote(source))
        {singleton, _opts} = Mnemonix.Singleton.Behaviour.establish_singleton(__CALLER__.module, opts)

        context = %Context{
          caller: __CALLER__,
          module: __MODULE__,
          source: source,
          docs: Keyword.get(opts, :docs, true),
          inline: Keyword.get(opts, :inline, false),
          singleton: singleton,
          only: Keyword.get(opts, :only, :all),
          except: Keyword.get(opts, :except, []),
        }

        defaults = source.__definitions__
        |> Enum.filter(fn definition ->
          Definition.function?(definition) and not Definition.hidden?(definition)
        end)
        |> Enum.filter(fn definition ->
          Enum.all?(Definition.arities(definition), fn arity ->
            Context.implement?(context, definition.name, arity)
          end)
        end)
        |> Enum.map(fn definition ->
          Mnemonix.Behaviour.compose_default(context, definition)
        end)

        [
          quote(do: @behaviour(unquote(__MODULE__))),
          defaults,
          quote(do: defoverridable(unquote(__MODULE__))),
          unquote(code)
        ]
        |> List.flatten()
        |> Enum.filter(&(&1))
      end
    end
  end

  # If we are inlining, we may need any and all functions, private ones included
  def compose_default(%Context{inline: true} = context, %Definition{} = definition) do
    compose_definition(context, definition)
  end

  # Otherwise we are only interested in public functions
  def compose_default(%Context{} = context, %Definition{kind: :def} = definition) do
    delegation = [do: compose_delegate(context, definition)]
    default = compose_definition(context, %{definition | body: delegation})

    if Definition.callback?(definition) do
      [compose_module_attribute(:impl, context.module), default]
    else
      [default]
    end
  end

  # Throw away anything else
  def compose_default(_context, _definition), do: nil

  defp compose_delegate(%Context{} = context, %Definition{} = definition) do
    args = Definition.args(definition)
    args = if context.singleton, do: [context.singleton | tl(args)], else: args
    compose_application(context.source, definition.name, args)
  end

  defp compose_definition(%Context{} = context, %Definition{kind: :def} = definition) do
    params = if context.singleton, do: tl(definition.params), else: definition.params
    [
      compose_docs(context, definition),
      compose_function(:def, definition.name, params, definition.guards, definition.body)
    ]
  end

  defp compose_definition(_context, %Definition{kind: :defp} = definition) do
    compose_function(:defp, definition.name, definition.params, definition.guards, definition.body)
  end

  defp compose_docs(%Context{docs: false}, _definition), do: compose_module_attribute(:doc, false)

  defp compose_docs(%Context{} = context, %Definition{} = definition) do
    doc = Definition.docs_with_replacements(definition, context.source, context.caller.module)
    compose_module_attribute(:doc, doc)
  end

  defp compose_function(:def, name, params, guards, body) do
    head = compose_head(name, params, guards)

    quote location: :keep do
      Kernel.def(unquote(head), unquote(body))
    end
  end

  defp compose_function(:defp, name, params, guards, body) do
    head = compose_head(name, params, guards)

    quote location: :keep do
      Kernel.defp(unquote(head), unquote(body))
    end
  end

  defp compose_head(name, params, []) do
    compose_call(name, params)
  end

  defp compose_head(name, params, guards) do
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
