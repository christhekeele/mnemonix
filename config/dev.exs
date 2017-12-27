use Mix.Config

config :mnemonix, stores: [Foo.Store, Bar.Store, Baz.Store]
config :mnemonix, Bar.Store, {Mnemonix.Stores.ETS, name: FizzBuzz}
config :mnemonix, Baz.Store, {Mnemonix.Stores.ETS, initial: [a: 1]}
