defmodule Mnemonix.Delegator do
  @moduledoc false

  defmacro __using__(opts) do
    module = Keyword.fetch!(opts, :module)
    for {name, arity} <- module.__info__(:functions) do
      quote location: :keep do
        @doc false
        if unquote(opts)[:singleton] do
          def unquote(name)(unquote_splicing(arity_to_args(arity - 1))) do
            unquote(module).unquote(name)((if unquote(opts)[:singleton] == true, do: __MODULE__, else: unquote(opts)[:singleton]), unquote_splicing(arity_to_args(arity - 1)))
          end
        else
          def unquote(name)(unquote_splicing(arity_to_args(arity))) do
            unquote(module).unquote(name)(unquote_splicing(arity_to_args(arity)))
          end
        end
      end
    end
  end

  def arity_to_args(arity) when is_number arity do
    for num <- 1..arity, do: Macro.var(:"arg#{num}", nil)
  end

end
