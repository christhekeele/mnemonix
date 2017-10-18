ExUnit.start()

exclusions = []

# Exclude doctests unless told not to.
exclusions = if System.get_env("DOCTESTS"), do: exclusions, else: [:doctest | exclusions]

# Exclude filesystem-dependent tests if the file system is not writable.

filesystem_dir = String.to_charlist(System.get_env("FILESYSTEM_TEST_DIR") || System.tmp_dir())

exclusions = case File.touch(Path.join(filesystem_dir, "writable.tmp")) do
  :ok ->
    File.rm_rf("writable.tmp")
    exclusions
  {:error, reason} ->
    Mix.shell.info """
    Cannot write to filesystem (path://#{filesystem_dir}): #{reason}
    Skipping file-dependent tests.
    """
    [:filesystem | exclusions]
end

# Exclude redis-dependent tests if redis is not available.

redis_host = String.to_charlist(System.get_env("REDIS_TEST_HOST") || "localhost")
redis_port = String.to_integer(System.get_env("REDIS_TEST_PORT") || "6379")

exclusions = case :gen_tcp.connect(redis_host, redis_port, []) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    exclusions
  {:error, reason} ->
    Mix.shell.info """
    Cannot connect to Redis (redis://#{redis_host}:#{redis_port}): #{:inet.format_error(reason)}
    Skipping redis tests.
    """
    [:redis | exclusions]
end

# Exclude memcached-dependent tests if memcached is not available.

memcached_host = String.to_charlist(System.get_env("REDIS_TEST_HOST") || "localhost")
memcached_port = String.to_integer(System.get_env("REDIS_TEST_PORT") || "11211")

exclusions = case :gen_tcp.connect(memcached_host, memcached_port, []) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    exclusions
  {:error, reason} ->
    Mix.shell.info """
    Cannot connect to Memcached (http://#{memcached_host}:#{memcached_port}): #{:inet.format_error(reason)}
    Skipping memcached tests.
    """
    [:memcached | exclusions]
end

# Exclude elasticsearch-dependent tests if elasticsearch is not available.

elastic_search_host = String.to_charlist(System.get_env("ELASTIC_SEARCH_TEST_HOST") || "127.0.0.1")
elastic_search_port = String.to_integer(System.get_env("ELASTIC_SEARCH_TEST_PORT") || "9200")

exclusions = case :gen_tcp.connect(elastic_search_host, elastic_search_port, []) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    exclusions
  {:error, reason} ->
    Mix.shell.info """
    Cannot connect to Elastic (http://#{elastic_search_host}:#{elastic_search_port}): #{:inet.format_error(reason)}
    Skipping ElasticSearch tests.
    """
    [:elastic_search | exclusions]
end

ExUnit.configure(exclude: exclusions)

defmodule Filesystem.TestHelpers do

  defmacro in_test_dir(dir \\ nil, [do: code]) do
    quote do
      File.cd!(unquote(dir) || Filesystem.TestHelpers.test_dir(), fn ->
        unquote code
      end)
    end
  end

  def test_dir(), do: unquote(filesystem_dir)

end

defmodule Elastic.TestHelpers do
  def wait_for_value(key, value, context, i \\ 1) do
    if(i==20) do
      :timeout
    else
      if Mnemonix.get(context[:store], key) == value do
        value
      else
        :timer.sleep(100); Elastic.TestHelpers.wait_for_value(key, value, context, i + 1)
      end
    end
  end

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
    quote do
      import Mnemonix.Test.Case
      import Filesystem.TestHelpers
    end
  end

end
