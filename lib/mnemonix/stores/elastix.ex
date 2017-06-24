if Code.ensure_loaded?(Elastix) do
  defmodule Mnemonix.Stores.Elastix do
    @moduledoc """
    A `Mnemonix.Store` that uses Elastix to store state in ElasticSearch.

        iex> {:ok, store} = Mnemonix.Stores.Elastix.start_link()
        iex> Mnemonix.put(store, "foo", "bar")
        iex> Mnemonix.get(store, "foo")
        "bar"
        iex> Mnemonix.delete(store, "foo")
        iex> Mnemonix.get(store, "foo")
        nil
        iex> Mnemonix.put(store, "baz", %{"x" => 1})
        iex> Mnemonix.get(store, "baz")
        %{"x" => 1}

    This store throws errors on the functions in `Mnemonix.Features.Enumerable`.
    """

    defmodule Exception do
      defexception [:message]
    end

    use Mnemonix.Store.Behaviour
    use Mnemonix.Store.Translator.Raw

    alias Mnemonix.Store
    alias HTTPoison.{Response,Error}

    ####
    # Mnemonix.Store.Behaviours.Core
    ##

    @doc """
    Connects to redis to store data using provided `opts`.

    ## Options

    - `url:` The ElasticSearch instance to connect to, string only.

      - *Default:* `"http://127.0.0.1:9200"`

    - `index:` The name of the index to store documents in.

      - *Default:* `mnemonix`

    - `type:` The name of the type to store documents in.

      - *Default:* `item

    """
    @spec setup(Mnemonix.Store.options)
      :: {:ok, state :: term} | {:stop, reason :: any}
    def setup(_) do
      Elastix.start()
      {:ok, %{}}
    end

    ####
    # Mnemonix.Store.Behaviours.Map
    ##

    @spec delete(Mnemonix.Store.t, Mnemonix.key)
      :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
    def delete(store = %Store{opts: opts}, key) do
      [url: url, index: index, type: type] = config(opts)

      case Elastix.Document.delete(url, index, type, key) do
        %Response{body: _} -> success(store)
        %Error{reason: reason} -> {:raise, Exception, [message: reason]}
      end

    end

    @spec fetch(Mnemonix.Store.t, Mnemonix.key)
      :: {:ok, Mnemonix.Store.t, {:ok, Mnemonix.value} | :error} | Mnemonix.Store.Behaviour.exception
    def fetch(store = %Store{opts: opts}, key) do
      [url: url, index: index, type: type] = config(opts)
      search = %{query: %{term: %{_id: key}}}

      case Elastix.Search.search(url, index, [type], search) do
        %Response{body: body} -> case get_in(body, ["hits", "hits"])  do
          [%{"_source" => %{"_value" => value}}] -> {:ok, store, {:ok, value }}
          [%{"_source" => value}]                -> {:ok, store, {:ok, value }}
          []       -> {:ok, store, :error}
          nil      -> {:ok, store, :error}
        end
        %Error{reason: reason} -> {:raise, Exception, [message: reason]}
      end

    end

    @spec put(Mnemonix.Store.t, Mnemonix.key, Store.value)
      :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
    def put(store = %Store{opts: opts}, key, value) do
      [url: url, index: index, type: type] = config(opts)

      value = case value do
        value when is_map(value) -> value
        value-> %{"_value" => value}
      end

      case Elastix.Document.index(url, index, type, key, value) do
        %Response{status_code: code} when code in [200, 201] -> success(store)
        %Response{body: body } -> {:raise, Exception, [message: get_in(body, ["error", "reason"]) ]}
        %Error{reason: reason} -> {:raise, Exception, [message: reason]}
      end
    end

    defp success(store) do
      if Mix.env == :test do
        # need to sleep during tests to ensure values processed by ElasticSearch
        :timer.sleep(2000)
      end

      {:ok, store}
    end

    defp config(opts) do
      [ url:   Keyword.get(opts, :url, "http://127.0.0.1:9200"),
        index: Keyword.get(opts, :index, "mnemonix"),
        type:  Keyword.get(opts, :type, "item") ]
    end

  end
end
