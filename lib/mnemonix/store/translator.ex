defmodule Mnemonix.Store.Translator do
  @moduledoc false

  @callback serialize_key(Mnemonix.Store.t, Mnemonix.key)
    :: term | no_return

  @callback serialize_value(Mnemonix.Store.t, Mnemonix.value)
    :: term | no_return

  @callback deserialize_key(Mnemonix.Store.t, term)
    :: Mnemonix.key | no_return

  @callback deserialize_value(Mnemonix.Store.t, term)
    :: Mnemonix.value | no_return

end
