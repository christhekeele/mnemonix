exclusions = []

# Exclude doctests unless told not to.
exclusions = if System.get_env("DOCTESTS"), do: exclusions, else: [:doctest | exclusions]

# Exclude redis tests if redis is not available.

redis_host = String.to_char_list(System.get_env("REDIS_TEST_HOST") || "localhost")
redis_port = String.to_integer(System.get_env("REDIS_TEST_PORT") || "6379")

exclusions = case :gen_tcp.connect(redis_host, redis_port, []) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    File.rm_rf("dump.rdb")
    exclusions
  {:error, reason} ->
    Mix.shell.info "Cannot connect to Redis (redis://#{redis_host}:#{redis_port}): #{:inet.format_error(reason)}\nSkipping redis tests."
    [:redis | exclusions]
end

# Exclude memcached tests if memcached is not available.

memcached_host = String.to_char_list(System.get_env("REDIS_TEST_HOST") || "localhost")
memcached_port = String.to_integer(System.get_env("REDIS_TEST_PORT") || "11211")

exclusions = case :gen_tcp.connect(memcached_host, memcached_port, []) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    exclusions
  {:error, reason} ->
    Mix.shell.info "Cannot connect to Memcached (http://#{memcached_host}:#{memcached_port}): #{:inet.format_error(reason)}\nSkipping memcached tests."
    [:memcached | exclusions]
end

# Start ExUnit.
ExUnit.start(exclude: exclusions)

defmodule Redis.TestHelpers do
  def test_host(), do: unquote(redis_host)
  def test_port(), do: unquote(redis_port)
end

defmodule Memcached.TestHelpers do
  def test_host(), do: unquote(memcached_host)
  def test_port(), do: unquote(memcached_port)
end

# Ensure cleanup of any test artifacts.
System.at_exit fn _ ->
  File.rm_rf("Mnesia.nonode@nohost")
  File.rm_rf("dump.rdb")
  :ok
end
