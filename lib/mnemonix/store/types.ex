defmodule Mnemonix.Store.Types do
  @moduledoc false

  @doc false
  defmacro __using__(types) do
    for type <- ~w[
      store
      impl
      opts
      state
      key
      value
      ttl
      bump_op
      exception
    ]a do
      if use?(types, type) do
        use!(type)
      end
    end
  end

  defp use?([], _),       do: true
  defp use?(types, type), do: type in types

  defp use!(:store) do
    quote location: :keep do
      @typep store :: Mnemonix.Store.t
    end
  end

  defp use!(:opts) do
    quote location: :keep do
      @typep opts  :: Mnemonix.Store.opts
    end
  end

  defp use!(:impl) do
    quote location: :keep do
      @typep impl  :: Mnemonix.Store.impl
    end
  end

  defp use!(:state) do
    quote location: :keep do
      @typep state :: Mnemonix.Store.state
    end
  end

  defp use!(:key) do
    quote location: :keep do
      @typep key   :: Mnemonix.Store.key
    end
  end

  defp use!(:value) do
    quote location: :keep do
      @typep value :: Mnemonix.Store.value
    end
  end

  defp use!(:ttl) do
    quote location: :keep do
      @typep ttl :: Mnemonix.Store.tll
    end
  end

  defp use!(:bump_op) do
    quote location: :keep do
      @typep bump_op :: Mnemonix.Store.bump_op
    end
  end

  defp use!(:exception) do
    quote location: :keep do
      @typep exception :: {:raise, Module.t, raise_opts :: Keyword.t}
    end
  end


end
