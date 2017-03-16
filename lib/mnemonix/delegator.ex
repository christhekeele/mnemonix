defmodule Mnemonix.Delegator do
  @moduledoc false

  # For a synopsis of this mechanism, refer to:
  # https://gist.github.com/josevalim/e0dae4d0cb568e142861

  defmacro __using__(opts) do
    module = Keyword.fetch!(opts, :module)
    singleton = opts[:singleton]
    for {name, arity} <- module.__info__(:functions),
        params = arity_to_params(if singleton, do: arity - 1, else: arity)
    do
      quote location: :keep do
        if unquote(singleton) do
          @store if unquote(singleton) == true, do: __MODULE__, else: unquote(singleton)
          @doc false
          def unquote(name)(unquote_splicing(params)) do
            unquote(module).unquote(name)(@store, unquote_splicing(params))
          end
        else
          @doc false
          def unquote(name)(unquote_splicing(params)) do
            unquote(module).unquote(name)(unquote_splicing(params))
          end
        end
      end
    end
  end

  def arity_to_params(0) do
    []
  end
  def arity_to_params(arity) when is_number arity do
    for num <- 1..arity, do: Macro.var(:"arg#{num}", nil)
  end

end
