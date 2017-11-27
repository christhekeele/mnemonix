ExUnit.start(timeout: 5000)

exclusions = []

# Exclude doctests unless told not to.
exclusions = if System.get_env("DOCTESTS"), do: exclusions, else: [:doctest | exclusions]

# Determine if we should raise if we can't run a portion of the suite.
mandatory = System.get_env("ALL_BACKENDS")

# Exclude filesystem-dependent tests if the file system is not writable.
filesystem_dir = String.to_charlist(System.get_env("FILESYSTEM_TEST_DIR") || System.tmp_dir())

exclusions = case File.touch(Path.join(filesystem_dir, "writable.tmp")) do
  :ok ->
    File.rm_rf("writable.tmp")
    exclusions
  {:error, reason} ->
    message = "Cannot write to filesystem (path://#{filesystem_dir}): #{reason}"
    if mandatory do
      raise RuntimeError, message
    else
      Mix.shell.info message
      Mix.shell.info "Skipping filesystem-dependent tests."
      [:filesystem | exclusions]
    end
end

# Exclude redis-dependent tests if redis is not available.
redis_host = System.get_env("REDIS_TEST_HOST") || "localhost"
redis_port = String.to_integer(System.get_env("REDIS_TEST_PORT") || "6379")

# Exclude memcached-dependent tests if memcached is not available.
memcached_host = System.get_env("REDIS_TEST_HOST") || "localhost"
memcached_port = String.to_integer(System.get_env("REDIS_TEST_PORT") || "11211")

# Exclude elasticsearch-dependent tests if elasticsearch is not available.
elastic_search_host = System.get_env("ELASTIC_SEARCH_TEST_HOST") || "127.0.0.1"
elastic_search_port = String.to_integer(System.get_env("ELASTIC_SEARCH_TEST_PORT") || "9200")

tcp_backends = [
  {"Redis", :redis, redis_host, redis_port},
  {"Memcached", :memcached, memcached_host, memcached_port},
  {"ElasticSearch", :elastic_search, elastic_search_host, elastic_search_port},
]

exclusions = Enum.reduce(tcp_backends, exclusions, fn {backend, tag, host, port}, exclusions ->
  case :gen_tcp.connect(String.to_charlist(host), port, []) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    exclusions
  {:error, reason} ->
    message = "Cannot connect to #{backend} (http://#{host}:#{port}): #{:inet.format_error(reason)}"
    if mandatory do
      raise RuntimeError, message
    else
      Mix.shell.info message
      Mix.shell.info "Skipping #{backend}-dependent tests."
      [tag | exclusions]
    end
  end
end)

ExUnit.configure(exclude: exclusions)

defmodule Filesystem.TestHelpers do

  defmacro in_test_dir(dir \\ nil, [do: code]) do
    quote location: :keep do
      File.cd!(unquote(dir) || Filesystem.TestHelpers.test_dir(), fn ->
        unquote code
      end)
    end
  end

  def test_dir(), do: unquote(filesystem_dir)

end

defmodule ElasticSearch.TestHelpers do
  def test_host(), do: unquote(elastic_search_host)
  def test_port(), do: unquote(elastic_search_port)
end

defmodule Redis.TestHelpers do
  def test_host(), do: unquote(redis_host)
  def test_port(), do: unquote(redis_port)
end

defmodule Memcached.TestHelpers do
  def test_host(), do: unquote(memcached_host)
  def test_port(), do: unquote(memcached_port)
end

defmodule Mnemonix.Test.Case do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Mnemonix.Test.Case
      import Filesystem.TestHelpers
    end
  end

end
