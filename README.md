Mnemonix
========

> *A generic, swappable interface to key-value stores.*

API
---

Architecture
------------

Mnemonix models key-value stores as GenServers with a Map-inspired client interface. This allows them to easily fit into both OTP supervision trees and replace existing Map operations.

A `Mnemonix.Server` can be started with `Mnemonix.Server.start_link(adapter, opts \\ [])`. A keyword list under `opts[:config]` will be passed to the underlying store state, and the rest are consumed as normal `GenServer.start_link` options.

Each server keeps a `Mnemonix.Store` struct as its state. This struct contains:

- `Mnemonix.Store.adapter` - A module that implements the `Mnemonix.Adapter` behaviour that can handle the 4 core functions.
- `Mnemonix.Store.config` -  The list of configuration options passed into `Mnemonix.start_link` that adapter can use to customize the behaviour of core functions.
- `Mnemonix.Store.state` - An optional internal state the adapter may use during its operations to keep track of things like connection pools, ports, and the like.

The `Mnemonix` module implements many of the high-level conveniences found in the `Map` module. All high-level conveniences can be broken down into 4 core functions:

- `Mnemonix.keys(store)` - Lists all keys in the store
- `Mnemonix.put(store, key, value)` - Stores value at key
- `Mnemonix.fetch(store, key)` - Retrieves value at key
- `Mnemonix.delete(store, key)` - Removes value at key

These core functions make `Mnemonix.Server` calls and casts to the `store` process returned by `Mnemonix.start_link`. 

When a core function is invoked on the server, it passes the arguments and server state to the corresponding adapter implementation. The adapter returns the new state (modified if necessary) and the value for the server to return (if any).

### One-off processes

```elixir
store = Mnemonix.Map.Store.start_link
# alternatively: store = Mnemonix.Store.start_link(adapter: Mnemonix.Map.Adapter)
#=> #PID<0.61.0>
Mnemonix.Store.get(store, :foo)
# => nil
Mnemonix.Store.put(store, :foo, :bar)
#=> #PID<0.61.0>
Mnemonix.Store.get(store, :foo)
# => :bar
```

### Extensible modules

```elixir
defmodule Custom.Store do
  use Mnemonix.Store, adapter: Mnemonix.Map.Adapter
  
  def get_fizz do
    get :fizz
  end
  
  def put_fizz(val) do
    put :fizz, val
  end
end

store = Custom.Store.start_link
# alternatively: store = Mnemonix.Store.start_link(adapter: Custom.Store.Adapter)
#=> Custom.Store
Mnemonix.Store.get(store, :foo)
# => nil
Mnemonix.Store.put(store, :foo, :bar)
#=> Custom.Store
Mnemonix.Store.get(store, :foo)
# => :bar

Custom.Store.get(:foo)
# => :bar
Custom.Store.put(:foo, :baz)
#=> Custom.Store
Custom.Store.get(:foo)
# => :baz

Custom.Store.get_fizz
#=> nil
Custom.Store.put_fizz(:buzz)
#=> Custom.Store
Custom.Store.get_fizz
#=> :buzz
```

Additionally, there are two ways to manage their lifecycle:

- In your own supervision trees
- As registered modules managed by the `Mnemonix.Supervisor`

### One-off processes

```elixir
store = Mnemonix.Map.Store.new
#=> Mnemonix.Store.Conn
Mnemonix.Store.get(store, :foo)
# => nil
Mnemonix.Store.put(store, :foo, :bar)
#=> Mnemonix.Store.Conn
Mnemonix.Store.get(store, :foo)
# => :bar
```

### Building blocks

### Registered modules

```elixir
# In your config/config.exs file
config :my_app, :mnemonix, stores: [
  Sample.Store
]

config :my_app, Sample.Store,
  adapter: Mnemonix.Map.Adapter
  
defmodule Sample.Store do
  use Mnemonix.Store, otp_app: :my_app
end

Sample.Store.get(:foo)
```


Installation
------------

  1. Add `mnemonix` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:mnemonix, "~> 0.1.0"}]
    end
    ```

  2. Ensure `mnemonix` is started before your application:

    ```elixir
    def application do
      [applications: [:mnemonix]]
    end
    ```
    
Name
----

###### Pronunciation: *`noo-MAHN-icks`*

> "Mnemonic systems are techniques or strategies consciously used to improve memory. They help use information already stored in long-term memory to make memorization an easier task."
>
> -- *[Mnemonics](https://en.wikipedia.org/wiki/Mnemonic)*, **Wikipedia**