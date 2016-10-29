Mnemonix
========

> *A unified interface to key-value stores.*

Synopsis
--------

`Mnemonix` aims to help you:

  - Get running with key-values stores with minimal ceremony
  - Experiment with different backends for your application
  - Offer end-users of your library liberty to choose their backend

It encodes the behaviour, lifecycle, and feature set of a key-value store in a common interface, normalizes different store APIs to conform to that interface, and exposes access to them with `GenServer` and `Map` APIs.

Learn more about creating a `Mnemonix.Store` and manipulating them with the `Mnemonix` API by [reading the docs](https://hexdocs.pm/mnemonix).

##### Pronunciation: *`noo-MAHN-icks`*

> Mnemonic systems are techniques or strategies consciously used to improve memory. They help use information already stored in long-term memory to make memorization an easier task.
>
> -- *[Mnemonics](https://en.wikipedia.org/wiki/Mnemonic)*, **Wikipedia**

Installation
------------

1. Add `Mnemonix` to your project's dependencies in its `mix.exs`:

```elixir
def deps do
  [{:mnemonix, "~> 0.1.0"}]
end
```

2. Ensure `Mnemonix` is started before your application:

```elixir
def application do
  [applications: [:mnemonix]]
end
```

3. Follow setup instructions for any key-value stores you want to use:

4. Run `mix deps.get`.

Contributing
------------

Pull requests are welcome and greatly appreciated!

Here are useful commands if you've just forked the project and want to contribute:

- `mix deps.get`: Get development dependencies
- `mix test`:     Run the tests
- `mix docs`:     Generate documentation
