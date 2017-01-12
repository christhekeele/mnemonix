defmodule Mnemonix.Delegator do

  defmacro __using__([module: module]) do
    quote location: :keep, bind_quoted: [module: module] do
      for {name, arity} <- module.__info__(:functions) do
        def unquote(name)(unquote_splicing(Mnemonix.Delegator.arity_to_args(arity))) do
          unquote(module).unquote(name)(unquote_splicing(Mnemonix.Delegator.arity_to_args(arity)))
        end
      end
    end
  end

  defmacro __using__(_) do
    raise ArgumentError, "must provide a `:module` to delegate to"
  end

  def arity_to_args(arity) when is_number arity do
    for num <- 0..arity, do: Macro.var(:"arg#{num}", nil)
  end

end
