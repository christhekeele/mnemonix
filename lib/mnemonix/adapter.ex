defmodule Mnemonix.Adapter do
  @moduledoc false

  defmodule Builder do
    @moduledoc false

    defmacro compile_adapter(env) do
      for {identifier, code} <- Module.get_attribute(env.module, :transforms) do
        IO.puts identifier
        build_adapter(identifier, code)
      end ++ [default_transform()]
    end

    def build_adapter(identifier, code) do
      quote do
        def transform(value, unquote(identifier), options) do
          case {value, options}, do: unquote(code)
        end
      end
    end

    def default_transform do
      quote do
        def transform(value, identifier, _) do
          IO.warn "could not find transformation for #{inspect identifier} in adapter #{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}"
          value
        end
      end
    end

    defmacro compile_pipeline(env) do
      for {adapter, transforms} <- Module.get_attribute(env.module, :adapters),
          {identifier, code} <- transforms
      do
        build_pipeline(adapter, identifier, code)
      end ++ [default_pipeline()]
    end

    def build_pipeline(adapter, identifier, code) do
      IO.puts "building #{inspect adapter} #{inspect identifier}"
      quote do
        def transform(value, unquote(identifier), [{unquote(adapter), options} | rest]) do
          transform (case {value, options}, do: unquote(code)), unquote(identifier), rest # TCO'd!
        end
        def transform(value, identifier, [unquote(adapter) | rest]) do
          IO.warn "no options provided to adapter #{inspect unquote(adapter)} to #{inspect identifier} with in pipeline #{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}"
          transform(value, identifier, rest)
        end
      end
    end

    def default_pipeline do
      quote do
        def transform(value, identifier, [{adapter, _} | rest]) do
          IO.warn "could not find adapter #{inspect adapter} to #{inspect identifier} with in pipeline #{__MODULE__}"
          transform(value, identifier, rest)
        end
        def transform(value, _, _), do: value
      end
    end

  end

  defmodule Transformer do
    @moduledoc false
    defmacro transform(identifier, [do: code]) do
      Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
      Module.put_attribute(__CALLER__.module, :transforms, {identifier, code})
    end

    defmacro serialize(do: code) do
      Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
      Module.put_attribute(__CALLER__.module, :transforms, {:serialize, code})
    end

    defmacro deserialize(do: code) do
      Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
      Module.put_attribute(__CALLER__.module, :transforms, {:deserialize, code})
    end
  end

  defmacro __using__(_) do
    quote do
      @before_compile {Builder, :compile_adapter}
      require Mnemonix.Adapter.Transformer
      import Mnemonix.Adapter.Transformer

      defmacro __using__(_) do
        Module.register_attribute(__CALLER__.module, :adapters, accumulate: true)
        Module.put_attribute(__CALLER__.module, :adapters, {__MODULE__, @transforms})
        quote do: @before_compile {Builder, :compile_pipeline}
      end
    end
  end

end

defmodule Mnemonix.Adapters.Namespace do
  @moduledoc false
  use Mnemonix.Adapter

  serialize do
    {key, prefix} -> prefix <> key
  end

  deserialize do
    {value, prefix} -> String.replace_prefix(value, prefix, "")
  end
end

defmodule Mnemonix.Adapters.Term do
  @moduledoc false
  use Mnemonix.Adapter

  serialize do
    {thing, options} -> :erlang.term_to_binary(thing, options)
  end

  deserialize do
    {thing, _} -> :erlang.binary_to_term(thing, [:safe])
  end
end

defmodule Pipeline do
  @moduledoc false
  use Mnemonix.Adapters.Namespace
  use Mnemonix.Adapters.Term
end

# adapters = [{Mnemonix.Adapters.Namespace, "foo"}, {Mnemonix.Adapters.Namespace, "bar"}, {Mnemonix.Adapters.Term, [:compressed]}]
# "baz" |> Pipeline.transform(:serialize, adapters) |> Pipeline.transform(:deserialize, :lists.reverse(adapters))
