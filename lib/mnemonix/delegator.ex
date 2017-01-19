defmodule Mnemonix.Delegator do
  @moduledoc false

  defmacro __using__(opts = [module: module]) do
    for {name, arity} <- module.__info__(:functions) do
      quote location: :keep do
        @doc """
        Delegates to `#{unquote(module |> Inspect.inspect(%Inspect.Opts{}))}.#{unquote(name)}/#{unquote(arity)}`.
        """
        if unquote(opts[:singleton]) do
          def unquote(name)(unquote_splicing(arity_to_args(arity - 1))) do
            unquote(module).unquote(name)(__MODULE__, unquote_splicing(arity_to_args(arity - 1)))
          end
        else
          def unquote(name)(unquote_splicing(arity_to_args(arity))) do
            unquote(module).unquote(name)(unquote_splicing(arity_to_args(arity)))
          end
        end
      end
    end
  end
  defmacro __using__(_) do
    raise ArgumentError, "must provide a `:module` to delegate to"
  end

  def arity_to_args(arity) when is_number arity do
    for num <- 1..arity, do: Macro.var(:"arg#{num}", nil)
  end

end
