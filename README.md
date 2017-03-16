Mnemonix
========

> *A unified interface to key-value stores.*

[hex]: https://hex.pm/packages/mnemonix
[hex-version-badge]:   https://img.shields.io/hexpm/v/mnemonix.svg?maxAge=86400&style=flat-square
[hex-downloads-badge]: https://img.shields.io/hexpm/dt/mnemonix.svg?maxAge=86400&style=flat-square
[hex-license-badge]:   https://img.shields.io/badge/license-MIT-7D26CD.svg?maxAge=86400&style=flat-square

![Version][hex-version-badge] ![Downloads][hex-downloads-badge] ![License][hex-license-badge]

## Synopsis

`Mnemonix` aims to help you:

  - Get running with key-values stores with minimal ceremony
  - Experiment with different key-value store backends for your application
  - Allow end-users of your library liberty to choose their preferred backend

It encodes the behaviour, lifecycle, and feature set of a key-value store behind a common `GenServer` interface, normalizes different store APIs to conform to that interface, polyfills stores lacking features, and exposes access to them through a familiar `Map` API.

[Learn more about starting a `Mnemonix.Store.Server` and manipulating it with the `Mnemonix` API in the documentation.](https://hexdocs.pm/mnemonix/index.html)

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
    [{:mnemonix, "~> 0.8.0"}]
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

Testing
-------

### Setup

Some parts of the test suite are contingent upon configration of out-of-memory systems. Detection of these systems can be configured through environment variables. If they can't be detected, the parts of the suite that rely on them will be skipped.

- Mnesia
  - `FILESYSTEM_TEST_DIR`: The location of a filesystem Elixir can read from and write to. 
    - Default: `System.tmp_dir/0`
- Redis
  - `REDIS_TEST_HOST`: The hostname of a redis server. 
    - Default: `localhost`
  - `REDIS_TEST_PORT`: The port on the host redis is accessible at. 
    - Default: `6379`
- Memcached
  - `MEMCACHED_TEST_HOST`: The hostname of a memcached instance. 
    - Default: `localhost`
  - `MEMCACHED_TEST_PORT`: The port on the host memcached is accessible at. 
    - Default: `11211`

### Doctests

By default, the test suite omits doctests. This is because, by nature of the library, for full working examples in documentation to act as integration tests, some external state must be stored in an out-of-memory system. Normal tests have the opportunity to correctly configure these systems; doctests do not.

If you wish to run these, use the environment variable `DOCTESTS=true`. For them to pass, your system must be configured using the defaults in the setup steps specified above.

The CI server fulfills these requirements, so if you can't, you can always configure your fork to use [travis](https://travis-ci.org) too, to get the same build environment we use to vet all pull requests.