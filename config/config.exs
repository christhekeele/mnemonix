use Mix.Config

configs = ["#{Mix.env}.exs"]

for config <- configs do
  if File.exists?(config), do: import_config(config)
end

# config :mnemonix, stores: [Foo.Store, Bar.Store, Baz.Store]
# config :mnemonix, Bar.Store, {Mnemonix.Stores.ETS, name: FizzBuzz}
# config :mnemonix, Baz.Store, {Mnemonix.Stores.ETS, initial: [a: 1]}
