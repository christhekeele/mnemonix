defmodule Mnemonix.Store.Translator do
  @moduledoc false

  @callback serialize_key(Mnemonix.key, Mnemonix.Store.t)
    :: serialized_key :: term | no_return

  @callback serialize_value(Mnemonix.value, Mnemonix.Store.t)
    :: serialized_value :: term | no_return

  @callback deserialize_key(serialized_key :: term, Mnemonix.Store.t)
    :: Mnemonix.key :: term | no_return

  @callback deserialize_value(serialized_value :: term, Mnemonix.Store.t)
    :: Mnemonix.value :: term | no_return

end
