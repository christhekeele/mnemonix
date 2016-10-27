Mnemonix
========

> *A common interface and GenServer wrapper around key-value stores.*

###### Pronunciation: *`noo-MAHN-icks`*

> "Mnemonic systems are techniques or strategies consciously used to improve memory. They help use information already stored in long-term memory to make memorization an easier task."
>
> -- *[Mnemonics](https://en.wikipedia.org/wiki/Mnemonic)*, **Wikipedia**

Synopsis
--------

The goal of Mnemonix is to make it easy to play around with various key-value stores, get running with them with minimal ceremony, and allow library developers whose works need access to a key-value store to defer the implementation decision to their end users.

Mnemonix encodes the common behaviour any key-value store library must have to be useful, normalizes them to conform to that interface, wraps access to them in a GenServer, and wraps access to that in an easy-to-use Map-style API.

Installation
------------

1. Add `mnemonix` and any key-value implementations you want to use to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mnemonix, "~> 0.1.0"},
    {:redix, ">= 0.0.0"},
  ]
end
```

2. Ensure `mnemonix` is started before your application and alongside your other key-value store implementations:

```elixir
def application do
  [applications: [:redix, :mnemonix]]
end
```

Usage
-----

Mnemonix's main goal is to make it quick to get started and easy to experiment with different key-value stores in your application.

```elixir
store = Mnemonix.new
#=> #PID<0.154.0>
```

### Direct reference to a store

If Elixir were said to have a built-in naïve distributed key-value store, that'd probably a `%{}` inside a GenServer. This is exactly what `Mnemonix.new` just gave us––think of it as a GenServer-powered `Map.new`.

If Elixir were said to have a standard key-value store API, it'd be the `Map` module. The other functions in `Mnemonix` act just like their `Map` counterparts:

```elixir
store = Mnemonix.new(fizz: 1)
{value, store} = Mnemonix.get(store, :foo)
#=> nil
{value, store} = Mnemonix.put_new(store, :foo, "bar")
#=> #PID<0.154.0>
{value, store} = Mnemonix.get(store, :foo)
#=> "bar"
{value, store} = Mnemonix.put_new(store, :foo, "baz")
#=> #PID<0.154.0>
{value, store} = Mnemonix.get(store, :foo)
#=> "bar"
{value, store} = Mnemonix.put(store, :foo, "baz")
#=> #PID<0.154.0>
{value, store} = Mnemonix.get(store, :foo)
#=> "baz"
{value, store} = Mnemonix.get_and_update(store, :fizz, &({ &1, &1 * 2}))
#=> {1, #PID<0.154.0>}
{value, store} = Mnemonix.get_and_update(store, :fizz, &({ &1, &1 * 2}))
#=> {2, #PID<0.154.0>}
{value, store} = Mnemonix.get(store, :fizz)
#=> 4
```

Note that not all `Map` methods are supported, since some just aren't be practical for every kind of key-value store.

Also notice that, unlike the Map API, we don't need to keep updating our reference to `store` with returned pids--the pid represents state that lives elsewhere, after all. The fact that Mnemonix returns the pid at all is just because it strictly conforms to the Map API so that these operations are similarly chainable.

### Supervisable stores

Let's explore more supervisable ways to use Mnemonix. `Mnemonix.new` is just shorthand for starting a `Mnemonix.Store` GenServer with the `Mnemonix.Map.Store` adapter:

```elixir
store = Mnemonix.new
# SAME AS
{:ok, store} = Mnemonix.Store.start_link(Mnemonix.Map.Store)
# SAME AS
{:ok, store} = Mnemonix.Map.Store.start_link
```

You can pass normal GenServer options into these functions:

```elixir
{:ok, store} = Mnemonix.Map.Store.start_link(name: Fred)
#=> {:ok, #PID<0.154.0>}
iex(2)> Mnemonix.put(Fred, :foo, :bar)
#=> Fred
iex(3)> Mnemonix.get(Fred, :foo)
#=> :bar
```

Now it's a little more obvious we don't need to capture the pid reference to the store after every operation. 

These `start_links` allow stores to fit in to any normal supervision tree, and the Mnemonix API works just as well on named servers as it does raw pids.

### Singleton stores

In fact, there's a shortcut to create a named store and use it without the initial `store` argument entirely:

```elixir
defmodule Fred do
  use Mnemonix.Singleton
end

Fred.start_link(Mnemonix.Map.Store)
#=> {:ok, #PID<0.154.0>}
Fred.get(:foo)
#=> nil
Fred.put(:foo, :bar)
#=> Fred
Fred.get(:foo)
#=> :bar
```

Singletons also allow us to extend the Mnemonix.DSL with our own behaviour:

```elixir
defmodule MyApp.Cache do
  use Mnemonix.Singleton
  
  def put_except_fizz(key, value) do
    if key == :fizz do
      # Stays consistent with 'return GenServer-compatible name' behaviour
      singleton
    else
      put key, value
    end
  end
end

MyApp.Cache.start_link(Mnemonix.Map.Store)
#=> {:ok, #PID<0.154.0>}
MyApp.Cache.put_except_fizz(:foo, :bar)
#=> MyApp.Cache
MyApp.Cache.get(:foo)
#=> :bar
MyApp.Cache.put_except_fizz(:fizz, :buzz)
#=> MyApp.Cache
MyApp.Cache.get(:fizz)
#=> nil
```

Note that these functions will not chain like `Mnemonix` ones do! We've moved away from the Map-inspired DSL for a more typical named GenServer interface.

### Adapters

Of course, the whole point of Mnemonix is that you're not just limited to Maps if you want to use a Map-like API to access key-value data. 

Mnemonix comes with many adapters. It natively supports two in-memory adapters for Map and ETS, and one persisted adapter for DETS. Other adapters are capable of bridging wider gaps to other types of key-value store but will only be loaded if support for them is detected.

Using other adapters is as simple as linking to another store:

```elixir
{:ok, store} = Mnemonix.Store.start_link(Mnemonix.ETS.Store)
# SAME AS
{:ok, store} = Mnemonix.ETS.Store.start_link
```

Everything we've discussed, you can accomplish with these ETS stores as well.

Available adapters are:

- `Mnemonix.Map.Store`
- ~~`Mnemonix.ETS.Store`~~
- ~~`Mnemonix.DETS.Store`~~
- ~~`Mnemonix.Ecto.Store`~~
- ~~`Mnemonix.Redix.Store`~~
- ~~`Mnemonix.ExRedis.Store`~~

### Advanced (in the pipeline)

#### Meta adapters

On top of those concrete adapters, Mnemonix offers several meta-adapters capable of composing key-value store operation across many other stores, following common patterns of usage.

Available meta-adapters are:

- ~~`Mnemonix.Meta.Pool.Store`~~: read from available one, write to all
- ~~`Mnemonix.Meta.Replica.Store`~~: read from leader, write to all, promote follower if leader crashes
- ~~`Mnemonix.Meta.Migration.Store`~~: write to new store, read checks it but falls back to original store, and writes back to new store if read missed

#### Migrating between adapters

Since the store behaviour gives every callback function an opportunity to modify not just the struct's private state, but also the original opts and the adapter, there's no reason why an app would have to be restarted to migrate between store types.

Replace the adapter with a Meta.Migration store, and then replace it again to your target store once migration misses are reduced. This could be powered by handle_cast commands or even hook into code_change somehow. The miss rate could be exposed through some sort of handle_info or explict handle_call for internal GenServer state.

#### Persistance

Could hook into the terminate callback to find a way to save in-memory stores before the system shuts down.

#### Supervisor spec support

Possible accept Supervisor.children specs as arguments to start_link, so that meta stores can tap into that sort of thing.

#### Mnemonix.Supervisor

Allow passing otp_app and reading from that config instead to get adapter type and/or store init opts.

#### Mnemonix.Application

Extend singletons to stop and start as a full application somehow.

Status
------

### Features

- Supports many different types of runtime and external stores
- Come with all adapters out-of-the-box, conditionally loaded if supporting store libraries are found
- Fits cleanly into any supervision tree
- Comes with a friendly `Map`-compatible API

### Limitations

- Can't set keys to expire (yet)
- Can't iterate over stores (Enumerable is not implemented since that could be detrimentally costly for some stores)
- Can't re-shape stores (Collectable is not implemented since there's no point making Enum.into work but none of the other Enum methods)
- Can't use Access behaviour (can't implement Access on stores since `store` is assumed to be a GenServer name, not a Struct)
- Can't use Kernel.get_in/put_in/pop_in/update_in helpers (Access is not implemented)

All of these limitations can be overcome (and have been in earlier incarnations), but
- I want to finalize the core architecture and implement it for many different stores before deciding how best to build a bolt-on replacement for expiration for stores that lack it
- I want to focus on the core interface before designing a 'not supported' interface since iteration is not a good fit for many key-value stores
- I want to focus on making Mnemonix easy to mount into supervision trees, but the Access protocol requires operating on structs instead of pids or GenServer names, and I don't feel like adding a `Mnemonix.Conn` struct layer of indirection right now.

### Architecture

Deciding on the right architecture for Mnemonix was (is) hard. The requirements that drive Mnemonix's design are:

- Stores should play nicely with supervision trees
- Features supported on one store adapter must be available to all adapters (by extending their behaviour in Elixir if need be)
- Implementing a new adapter should be as easy as implementing a handful of core functions, without the Mnemonix interface getting in the way
- Stores should act as much like Maps as possible
- As much of the Map DSL as possible should automatically be built from these core functions
- But the adapter should be able to override any method with an optimized store-specific implementation
- Adapters should be able to raise errors and trigger warnings at the Map DSL call site

Here's how those requirements are met currently. It's expected that you read this guide alongside the source code of each module, to get an idea of what's going on behind the scenes.

### Mnemonix.Store

The `Mnemonix.Store` server (and corresponding struct) is the heart of Mnemonix. Since the core abstraction is a GenServer we can start stores wherever we need them in our supervision tree. The store state struct has 3 properties:

- `adapter:` the module implementing `Mnemonix.Store.Behaviour`
- `opts:` whatever user-supplied configuration this store needs to remember
- `state`: whatever internal information this store needs to remember
  
Rather than offer its own client API, it just focuses on callbacks and a single function to start the server. This function, `Mnemonix.start_link({adapter, opts}, config)`, just starts a new GenServer registered with the traditional `config` and passes it the provided options.

All of its callbacks defer implementation details to the adapter:

  - The `init` callback takes the given `adapter` and `opts` to build a new `Menmonix.Store` struct for the initial state.
  - The `handle_call` callback just invokes functions on the adapter, passing in the server state and any provided arguments.
  
We know the adapter will do what the server expects it to because it's implemented the interface that makes Mnemonix possible: `Mnemonix.Store.Behaviour`.
  
### Mnemonix.Store.Behaviour

This behaviour defines the functions an adapter must implement to handle the calls the server will make to it.

The first behaviour callback powers `Mnemonix.Store.init`

  - init(Memonix.Store.opts) :: {:ok, Mnemonix.Store.state}
  
    When the Mnemonix.Server first starts, it has an adapter and user-supplied configuration. All it's missing to create a store struct is to do any setup and return a private state. This is where that happens; you might need to initialize a client or a database connection and save it for later.
    
The other behaviours power `Mnemonix.Store.handle_call` invocations–one callback per potential store operation. There are only 3 core operations we must implement:
    
  - put(Mnemonix.Store.t, key, value) :: {:ok, Mnemonix.Store.t}
  - fetch(Mnemonix.Store.t, key) :: {:ok, Mnemonix.Store.t, value}
  - delete(Mnemonix.Store.t, key) :: {:ok, Mnemonix.Store.t}
  
This lets us add, lookup, and remove entries from the store. Notice that while `fetch` is expected to return a value, all of them are expected to return the next (potentially modified) version of the store so the server can keep spinning. While the private state of a database connection might not change in-between calls, our in-memory stores need to be able to update the server state.

With these 3 core key-value store operations, Mnemonix can intuit the rest. You'll notice there are many more optional callbacks in `Mnemonix.Store.Behaviour`. Every store receives default implementations of these through `Mnemonix.Store.Behaviour.Default`, which defines all the other operations in terms of just these 3 core operations. However, the store can override them with implementation-native ones if desired.

This fulfills most of our requirements. However, the Mnemonix.Store server is not easy to use–we have no client API to simply sending it messages yet.

### Mnemonix

The `Mnemonix` module mimics the `Map` module, but instead of doing any logic whatsoever, it rephrases each operation in terms of a GenServer call, and fits the GenServer response into the same shapes Map would return. This is the client API for our GenServer.

However, instead of operating on Maps as the first argument, it operates on pids and GenServer names, allowing us to talk to our GenServer however we want.

In summary, we're effectively doing 4 things to make Mnemonix work:

  - `Mnemonix.Store` wraps a standard store representation with an adapter invocation mechanism
  - `Mnemonix.Store.Behaviour` defines how adapters should bridge the gap between adapter invocations and the underlying store
  - `Mnemonix.Store.Behaviour.Default` reduces the amount of work adapters have to do to be compatible with a Map-like API
  - `Mnemonix` lets you trigger adapter invocations with that Map-like API

All adapters have to do is whatever setup initial setup they require, and honor 3 low-level function callbacks to be fully Mnemonix-compatible.