defmodule Mnemonix.Adapter do
  @moduledoc false

  defmodule Builder do
    @moduledoc false

    defmacro compile_adapter(env) do
      for {action, code} <- Module.get_attribute(env.module, :transforms) do
        build_adapter(action, code)
      end ++ [default_transform()]
    end

    def build_adapter(action, code) do
      quote do
        def transform(value, unquote(action), options) do
          case {value, options}, do: unquote(code)
        end
      end
    end

    def default_transform do
      quote do
        def transform(value, action, _) do
          IO.warn """
            could not find transformation for #{action} in adapter
            #{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}, moving on...
          """
          value
        end
      end
    end

    defmacro compile_pipeline(env) do
      for {adapter, transforms} <- Module.get_attribute(env.module, :adapters),
          {action, code} <- transforms
      do
        build_pipeline(adapter, action, code)
      end ++ [default_pipeline()]
    end

    def build_pipeline(adapter, action, code) do
      quote do
        def transform(value, unquote(action), [{unquote(adapter), options} | rest]) do
          transform (case {value, options}, do: unquote(code)), unquote(action), rest # TCO'd!
        end
        def transform(value, action, [unquote(adapter) | rest]) do
          IO.warn """
            no options provided to adapter #{unquote(adapter |> Inspect.inspect(%Inspect.Opts{}))}
            to #{action} with in pipeline #{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}, moving on...
          """
          transform(value, action, rest)
        end
      end
    end

    def default_pipeline do
      quote do
        def transform(value, action, [{adapter, _} | rest]) do
          IO.warn """
            could not find adapter #{adapter |> Inspect.inspect(%Inspect.Opts{})} to #{action} with
            in pipeline #{__MODULE__ |> Inspect.inspect(%Inspect.Opts{})}, moving on...
          """
          transform(value, action, rest)
        end
        def transform(value, _, _), do: value
      end
    end

  end

  defmodule Transformer do
    @moduledoc false
    defmacro transform(action, [do: code]) do
      Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
      Module.put_attribute(__CALLER__.module, :transforms, {action, code})
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
  use Mnemonix.Adapter, default_options: [compression: 9]

  serialize do
    {thing, options} -> :erlang.term_to_binary(thing, compressed: Keyword.get(options, :compression, 0))
  end

  deserialize do
    {thing, options} -> :erlang.binary_to_term(thing, (if options[:safe], do: [:safe], else: []))
  end
end

defmodule Pipeline do
  @moduledoc false
  use Mnemonix.Adapters.Namespace
  use Mnemonix.Adapters.Term
end

# adapters = [{Mnemonix.Adapters.Namespace, "foo"}, {Mnemonix.Adapters.Namespace, "bar"}, {Mnemonix.Adapters.Term, [:compressed]}]
# "baz" |> Pipeline.transform(:serialize, adapters) |> Pipeline.transform(:deserialize, :lists.reverse(adapters))
