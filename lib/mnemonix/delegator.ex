defmodule Mnemonix.Delegator do
  @moduledoc false

  # For a general synopsis of this mechanism, refer to:
  # https://gist.github.com/josevalim/e0dae4d0cb568e142861

  defmacro __using__(opts) do
    module = Keyword.fetch!(opts, :module)
    singleton = Keyword.get(opts, :singleton)
    for {name, arity} <- module.__info__(:functions) do
      if singleton do
        store = if singleton == true, do: __CALLER__.module, else: singleton
        delegate_singleton(module, name, arity, store)
      else
        delegate_standard(module, name, arity)
      end
    end
  end

  # Singleton start_links are special:

  # Without options, they should call the version below
  defp delegate_singleton(_module, :start_link, 1, _store) do
    quote do
      @doc false
      def start_link(impl) do
        start_link(impl, [])
      end
      defoverridable [start_link: 1]
    end
  end

  # With options, they use the store for the server name if one is not given
  defp delegate_singleton(module, :start_link, 2, store) do
    quote do
      @doc false
      def start_link(impl, opts) do
        opts = if Keyword.get(opts, :server), do: opts, else: Keyword.put(opts, :server, [])
        opts = Kernel.put_in(opts, [:server, :name], unquote(store))
        unquote(module).start_link(impl, opts)
      end
      defoverridable [start_link: 2]
    end
  end

  # All other singletons just inject the store name into the params list
  defp delegate_singleton(module, name, arity, store) do
    params = arity_to_params(arity - 1)
    quote do
      @doc false
      def unquote(name)(unquote_splicing(params)) do
        unquote(module).unquote(name)(unquote_splicing([store | params]))
      end
      defoverridable [{unquote(name), unquote(length(params))}]
    end
  end

  defp delegate_standard(module, name, arity) do
    params = arity_to_params(arity)
    quote do
      @doc false
      def unquote(name)(unquote_splicing(params)) do
        unquote(module).unquote(name)(unquote_splicing(params))
      end
      defoverridable [{unquote(name), unquote(length(params))}]
    end
  end

  defp arity_to_params(0) do
    []
  end
  defp arity_to_params(arity) when is_integer arity and arity > 0 do
    for num <- 1..arity, do: Macro.var(:"arg#{num}", nil)
  end

end
