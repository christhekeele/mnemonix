defmodule Mnemonix.Transform do
  @moduledoc false

  defmodule Builder do
    @moduledoc false

    defmacro __before_compile__(env) do
      for {identifier, code} <- Module.get_attribute(env.module, :transforms) do
        quote location: :keep do
          def transform(value, unquote(identifier), options) do
            case {value, options}, do: unquote(code)
          end
        end
      end ++ [
        quote location: :keep do
          def transform(value, _, _), do: value
        end
      ]
    end
  end

  defmodule Pipeline do
    @moduledoc false

    defmacro __before_compile__(env) do
      for {transformer, transforms} <- Module.get_attribute(env.module, :transforms) do
        for {identifier, code} <- transforms do
          quote location: :keep do
            def transform(value, unquote(identifier), [{unquote(transformer), options} | rest]) do
              # value = case {value, options}, do: unquote(code)
              transform (case {value, options}, do: unquote(code)), unquote(identifier), rest # TCO'd!
            end
          end
        end
      end ++ [
        quote location: :keep do
          def transform(value, identifier, [transform | rest]) do
            transform(value, identifier, rest)
          end
          def transform(value, _, _), do: value
        end
      ]
    end
  end

  defmacro __using__(_) do
    quote location: :keep, unquote: false do
      @before_compile Builder
      require Mnemonix.Transform
      import Mnemonix.Transform

      defmacro __using__(_) do
        Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
        Module.put_attribute(__CALLER__.module, :transforms, {__MODULE__, @transforms})
        quote location: :keep do
          @before_compile Pipeline
        end
      end

    end
  end

  defmacro transform(identifier, [do: code]) do
    Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
    Module.put_attribute(__CALLER__.module, :transforms, {identifier, code})
  end

  defmacro serialize(identifier, [do: code]) when identifier in [:key, :value] do
    Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
    Module.put_attribute(__CALLER__.module, :transforms, {{:serialize, identifier}, code})
  end

  defmacro deserialize(identifier, [do: code]) when identifier in [:key, :value] do
    Module.register_attribute(__CALLER__.module, :transforms, accumulate: true)
    Module.put_attribute(__CALLER__.module, :transforms, {{:deserialize, identifier}, code})
  end
end

defmodule Stringify do
  @moduledoc false
  use Mnemonix.Transform

  serialize :key do
    {key, prefix} -> prefix <> key
  end

  deserialize :value do
    {value, prefix} -> String.replace_prefix(value, prefix, "")
  end
end

defmodule Pipeline do
  @moduledoc false
  use Stringify
end
