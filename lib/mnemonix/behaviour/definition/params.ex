defmodule Mnemonix.Behaviour.Definition.Params do
  @moduledoc false

  def arities(params) do
    {arity, defaults} = Enum.reduce(params, {0, 0}, fn
      {:\\, _, [_arg, _default]}, {arity, defaults} ->
        {arity, defaults + 1}
      _ast, {arity, defaults} ->
        {arity + 1, defaults}
    end)
    Range.new(arity, arity + defaults)
  end

  def normalize(params) do
    params
    |> Enum.with_index(1)
    |> Enum.map(&normalize_param/1)
  end

  defp normalize_param({{:\\, meta, [param, default]}, index}) do
    {{:\\, meta, [normalize_param({param, index}), normalize_param({default, index})]}, index}
  end

  defp normalize_param({{:_, meta, context}, index}) do
    {String.to_atom("arg#{index}"), meta, context}
  end

  defp normalize_param({{name, meta, context}, _}) when is_atom(name) and (is_atom(context) or context == nil) do
    string = Atom.to_string(name)

    if String.starts_with?(string, "_") do
      {String.to_atom(String.trim_leading(string, "_")), meta, context}
    else
      {name, meta, context}
    end
  end

  defp normalize_param({{call, meta, args}, index}) when is_list(args) do
    params = Enum.map(args, fn param -> normalize_param({param, index}) end)
    {call, meta, params}
  end

  defp normalize_param({{call, meta, args}, index}) when is_list(args) do
    params = Enum.map(args, fn param -> normalize_param({param, index}) end)
    {call, meta, params}
  end

  defp normalize_param({{two, tuple}, index}) do
    {normalize_param({two, index}), normalize_param({tuple, index})}
  end

  defp normalize_param({literal, _}) do
    literal
  end

  def strip_matches(params) do
    Macro.prewalk(params, fn
      {:=, _, [arg1, arg2]} -> pick_match(arg1, arg2)
      ast -> ast
    end)
  end

  defp pick_match({name, meta, context}, _arg2) when is_atom(name) and (is_atom(context) or context == nil) do
    {name, meta, context}
  end

  defp pick_match(_arg1, {name, meta, context}) when is_atom(name) and (is_atom(context) or context == nil) do
    {name, meta, context}
  end

  defp pick_match(arg1, arg2) do
    description = """
    could not resolve match into variable name;
    either the left or right side of matches in
    callback implementations must be a simple variable.
    Got: `#{Macro.to_string(arg1)} = #{Macro.to_string(arg2)}`
    """
    raise CompileError, description: description
  end

  def strip_defaults(params) do
    Macro.prewalk(params, fn
      {:\\, _, [arg, _default]} -> arg
      ast -> ast
    end)
  end
end
