if Code.ensure_loaded?(Elastix) do
  defmodule Mnemonix.Stores.Elastix do
    @moduledoc """
    A `Mnemonix.Store` that uses Elastix to store state in ElasticSearch.

    This store throws errors on the functions in `Mnemonix.Features.Enumerable`.
    """

    defmodule Exception do
      defexception [:message]
    end


    defmodule Conn do
      defstruct [
        url: "http://127.0.0.1:9200",
        index: :mnemonix,
        type: :item,
        refresh: true,
      ]
    end

    use Mnemonix.Store.Behaviour
    use Mnemonix.Store.Translator.Raw

    alias Mnemonix.Store
    alias HTTPoison.{Response,Error}

    ####
    # Mnemonix.Store.Behaviours.Core
    ##

    @doc """
    Connects to ElasticSearch to store data using provided `opts`.

    ## Options

    - `url:` The url of the ElasticSearch instance to connect to.

      - *Default:* `"http://127.0.0.1:9200"`

    - `index:` The name of the index to store documents in.

      - *Default:* `:mnemonix`

    - `type:` The name of the type to store documents in.

      - *Default:* `:item`

    - `refresh:` Whether or not to force the ElasticSearch instance to reindex after every request.

      - *Default:* `true`

    """
    @spec setup(Mnemonix.Store.options)
      :: {:ok, state :: term} | {:stop, reason :: any}
    def setup(opts) do
      {:ok, struct(Conn, opts)}
    end

    ####
    # Mnemonix.Store.Behaviours.Map
    ##

    @spec delete(Mnemonix.Store.t, Mnemonix.key)
      :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
    def delete(store = %Store{state: %Conn{url: url, index: index, type: type, refresh: refresh}}, key) do
      case Elastix.Document.delete(url, index, type, key, %{refresh: refresh}) do
        {:ok, %Response{body: _}} -> {:ok, store}
        {:error, %Error{reason: reason}} -> {:raise, Exception, [message: reason]}
      end

    end

    @spec fetch(Mnemonix.Store.t, Mnemonix.key)
      :: {:ok, Mnemonix.Store.t, {:ok, Mnemonix.value} | :error} | Mnemonix.Store.Behaviour.exception
    def fetch(store = %Store{state: %Conn{url: url, index: index, type: type}}, key) do
      search = %{query: %{term: %{_id: key}}}

      case Elastix.Search.search(url, index, [type], search) do
        {:ok, %Response{body: body}} -> case get_in(body, ["hits", "hits"])  do
          [%{"_source" => %{"_value" => value}}] -> {:ok, store, {:ok, value}}
          [%{"_source" => value}]                -> {:ok, store, {:ok, value}}
          []                                     -> {:ok, store, :error}
          nil                                    -> {:ok, store, :error}
        end
        {:error, %Error{reason: reason}} -> {:raise, Exception, [message: reason]}
      end

    end

    @spec put(Mnemonix.Store.t, Mnemonix.key, Store.value)
      :: {:ok, Mnemonix.Store.t} | Mnemonix.Store.Behaviour.exception
    def put(store = %Store{state: %Conn{url: url, index: index, type: type, refresh: refresh}}, key, value) do
      value = if is_map(value), do: value, else:  %{"_value" => value}

      case Elastix.Document.index(url, index, type, key, value, %{refresh: refresh}) do
        {:ok, %Response{status_code: code}} when code in [200, 201] -> {:ok, store}
        {:ok, %Response{body: body }} -> {:raise, Exception, [message: get_in(body, ["error", "reason"]) ]}
        {:error, %Error{reason: reason}} -> {:raise, Exception, [message: reason]}
      end
    end

  end
end
