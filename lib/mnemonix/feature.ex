defmodule Mnemonix.Feature do
  @moduledoc false

  defmodule Registry do
    @moduledoc false
    defmacro __before_compile__(env) do
      for feature <- Module.get_attribute(env.module, :features) do
        quote location: :keep do
          use Mnemonix.Delegator, module: unquote(feature)
        end
      end
    end
  end

  defmacro __using__([module: module]) do
    quote location: :keep do
      @before_compile Registry
      Module.register_attribute(__MODULE__, :features, accumulate: true)
      Module.put_attribute(__MODULE__, :features, unquote(module))
    end
  end


end
