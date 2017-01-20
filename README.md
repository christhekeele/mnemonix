Mnemonix
========

> *A unified interface to key-value stores.*

[hex]: https://hex.pm/packages/mnemonix
[hex-version-badge]:   https://img.shields.io/hexpm/v/mnemonix.svg?maxAge=86400&style=flat-square
[hex-downloads-badge]: https://img.shields.io/hexpm/dt/mnemonix.svg?maxAge=86400&style=flat-square
[hex-license-badge]:   https://img.shields.io/badge/license-MIT-7D26CD.svg?maxAge=86400&style=flat-square

[![Version][hex-version-badge] ![Hex][hex-downloads-badge] ![License][hex-license-badge]][hex]

## Synopsis

`Mnemonix` aims to help you:

  - Get running with key-values stores with minimal ceremony
  - Experiment with different key-value store backends for your application
  - Allow end-users of your library liberty to choose their preferred backend

It encodes the behaviour, lifecycle, and feature set of a key-value store behind a common `GenServer` interface, normalizes different store APIs to conform to that interface, polyfill stores lacking features, and exposes access to them through a familiar `Map` API.

Learn more about starting a `Mnemonix.Store.Server` and manipulating it with the `Mnemonix` API in the [documentation](https://hexdocs.pm/mnemonix/index.html).

##### Pronunciation: **`/nɛˈmɑːnɪks/`** – *`noo-MAHN-icks`*

> Mnemonic systems are techniques or strategies consciously used to improve memory. They help use information already stored in long-term memory to make memorization an easier task.
>
> — *[Mnemonics](https://en.wikipedia.org/wiki/Mnemonic)*, **Wikipedia**

*Not to be confused with the mnemonicode library, [`Mnemonex`](https://github.com/mwmiller/mnemonex).*

## Status

|         :thumbsup:         |  [Continuous Integration][status]   |        [Test Coverage][coverage]         |
|:--------------------------:|:-----------------------------------:|:----------------------------------------:|
|      [Master][master]      |   ![Build Status][master-status]    |   ![Coverage Status][master-coverage]    |
| [Development][development] | ![Build Status][development-status] | ![Coverage Status][development-coverage] |

[status]: https://travis-ci.org/christhekeele/mnemonix
[coverage]: https://coveralls.io/github/christhekeele/mnemonix

[master]: https://github.com/christhekeele/mnemonix/tree/master
[master-status]: https://img.shields.io/travis/christhekeele/mnemonix/master.svg?maxAge=86400&style=flat-square
[master-coverage]: https://img.shields.io/coveralls/christhekeele/mnemonix/master.svg?maxAge=86400&style=flat-square

[development]: https://github.com/christhekeele/mnemonix/tree/development
[development-status]: https://img.shields.io/travis/christhekeele/mnemonix/development.svg?maxAge=86400&style=flat-square
[development-coverage]: https://img.shields.io/coveralls/christhekeele/mnemonix/development.svg?maxAge=86400&style=flat-square

## Features

Obviously, `Mnemonix` gives you `Map`-style functions to manipulate various key-value stores. However, `Mnemonix` also offers extra features beyond simple Map functions. Stores that don't natively support these features have the capability added through an Elixir polyfill, guaranteeing you can use and switch stores without worrying about what features they support under the hood.

Available features are:

- `Mnemonix.Features.Map` - The key-value manipulation you know and love
- `Mnemonix.Features.Bump` - Increment/decrement integer values
- `Mnemonix.Features.Expiry` - Set entries to remove themselves from the store with a ttl

## Installation

- Add `Mnemonix` to your project's dependencies in its `mix.exs`:

  ```elixir
  def deps do
    [{:mnemonix, "~> 0.6.2"}]
  end
  ```

- Ensure `Mnemonix` is started before your application:

  ```elixir
  def application do
    [applications: [:mnemonix]]
  end
  ```

## Contributing

[Pull requests](https://github.com/christhekeele/mnemonix/pulls) are welcome and greatly appreciated!

Here are some useful commands if you've just forked the project and want to contribute:

- `mix deps.get` - Get development dependencies
- `mix test` - Run the test suite
- `mix credo` - Run static code analysis on Elixir source
- `mix dialyzer` - Run static code analysis on compiled BEAM bytecode
- `mix docs` - Generate documentation files
- `mix clean` - If any of the above stop behaving as expected
