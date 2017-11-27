if Code.ensure_loaded?(Elastix) do
  defmodule Mnemonix.Stores.Elastix do
    @moduledoc """
    A `Mnemonix.Store` that uses Elastix to store state in ElasticSearch.

    This store raises errors on the functions in `Mnemonix.Features.Enumerable`.
    """

    alias Mnemonix.Store
    alias HTTPoison.{Response,Error}

    use Store.Behaviour
    use Store.Translator.Raw

    defmodule Exception do
      defexception [:message]
    end

    defmodule Conn do
      @moduledoc false

      defstruct [
        url: "http://127.0.0.1:9200",
        index: :mnemonix,
        type: :item,
        refresh: true,
      ]
    end

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
    @impl Store.Behaviours.Core
    @spec setup(Store.options)
      :: {:ok, state :: term} | {:stop, reason :: any}
    def setup(opts) do
      {:ok, struct(Conn, opts)}
    end

  ####
  # Mnemonix.Store.Behaviours.Map
  ##

    @impl Store.Behaviours.Map
    @spec delete(Store.t, Mnemonix.key)
      :: Store.Server.instruction(:ok)
    def delete(store = %Store{state: %Conn{url: url, index: index, type: type, refresh: refresh}}, key) do
      case Elastix.Document.delete(url, index, type, key, %{refresh: refresh}) do
        {:ok, %Response{body: _}} -> {:ok, store, :ok}
        {:error, %Error{reason: reason}} -> {:raise, Exception, [message: reason]}
      end

    end

    @impl Store.Behaviours.Map
    @spec fetch(Store.t, Mnemonix.key)
      :: Store.Server.instruction({:ok, Mnemonix.value} | :error)
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

    @impl Store.Behaviours.Map
    @spec put(Store.t, Mnemonix.key, Mnemonix.value)
      :: Store.Server.instruction(:ok)
    def put(store = %Store{state: %Conn{url: url, index: index, type: type, refresh: refresh}}, key, value) do
      value = if is_map(value), do: value, else:  %{"_value" => value}

      case Elastix.Document.index(url, index, type, key, value, %{refresh: refresh}) do
        {:ok, %Response{status_code: code}} when code in [200, 201] -> {:ok, store, :ok}
        {:ok, %Response{body: body }} -> {:raise, Exception, [message: get_in(body, ["error", "reason"]) ]}
        {:error, %Error{reason: reason}} -> {:raise, Exception, [message: reason]}
      end
    end

  end
end
