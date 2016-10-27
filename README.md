Mnemonix
========

> *A common interface and GenServer wrapper around key-value stores.*

Features
--------

- Supports many different types of runtime and external stores
- Come with all adapters out-of-the-box, conditionally loaded if supporting store libraries are found
- Fits cleanly into any supervision tree
- Comes with a friendly `Map`-compatible API

Limitations
-----------

- Can't set keys to expire (yet)
- Can't iterate over stores (Enumerable is not implemented since that could be detrimentally costly for some stores)
- Can't re-shape stores (Collectable is not implemented since there's no point making Enum.into work but none of the other Enum methods)
- Can't use Access behaviour (can't implement Access on stores since `store` is assumed to be a GenServer name, not a Struct)
- Can't use Kernel.get_in/put_in/pop_in/update_in helpers (Access is not implemented)

All of these limitations can be overcome (and have been in earlier incarnations), but
- I want to finalize the core architecture and implement it for many different stores before deciding how best to build a bolt-on replacement for expiration for stores that lack it
- I want to focus on the core interface before designing a 'not supported' interface since iteration is not a good fit for many key-value stores
- I want to focus on making Mnemonix easy to mount into supervision trees, but the Access protocol requires operating on structs instead of pids or GenServer names, and I don't feel like adding a `Mnemonix.Conn` struct layer of indirection right now.

Usage
-----

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
    
Name
----

###### Pronunciation: *`noo-MAHN-icks`*

> "Mnemonic systems are techniques or strategies consciously used to improve memory. They help use information already stored in long-term memory to make memorization an easier task."
>
> -- *[Mnemonics](https://en.wikipedia.org/wiki/Mnemonic)*, **Wikipedia**

Architecture
------------

Deciding on the right architecture for Mnemonix was (is) hard. The requirements that drive Mnemonix's design are:

- Stores should play nicely with supervision trees
- Features supported on one store adapter must be available to all adapters (by extending their behaviour in Elixir if need be)
- Implementing a new adapter should be as easy as implementing a handful of core functions, without the Mnemonix interface getting in the way
- Stores should act as much like Maps as possible
- As much of the Map DSL as possible should automatically be built from these core functions
- But the adapter should be able to override any method with an optimized store-specific implementation

Here's how those requirements are met currently. It's expected that you read this guide alongside the source code, to get an idea of what's going on behind the scenes.

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