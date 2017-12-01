if Code.ensure_loaded?(Plug) do
  defmodule Plug.Session.MNEMONIX do
    @moduledoc """
    Stores the session in a Mnemonix store.

    This store does not create the Mnemonix store; it expects that a reference
    to an existing store server is passed in as an argument.

    We recommend carefully choosing the store type for production usage.
    Consider: persistence, cleanup, and cross-node availability (or lack thereof).

    The session id is used as a key to reference the session within the store;
    the session itself is encoded as the two-tuple:

        {timestamp :: :erlang.timestamp, session :: map}

    The timestamp is updated whenever there is a read or write to the table,
    and may be used to detect if a session is still active.

    ## Options
      * `:mnemonix` - `t:GenServer.name/0` reference (required)

    ## Examples

        # Start a named store when the application starts
        Mnemonix.Stores.Map.start_link(name: My.Plug.Session)

        # Use the session plug with the store name
        plug Plug.Session, store: :mnemonix, key: "_my_app_session", mnemonix: My.Plug.Session
    """

    @behaviour Plug.Session.Store
    alias Plug.Session.Store

    defmodule Exception do
      defexception [:message]

      def exception(opts) do
        %__MODULE__{message: Keyword.get(opts, :message, "error in Mnemonix session plug")}
      end
    end

    @sid_bytes 96

    @spec init(Plug.opts)
      :: GenServer.name | no_return
    def init(opts) do
      Keyword.fetch!(opts, :mnemonix)
    end

    @spec get(Plug.Conn.t, Store.cookie, GenServer.name)
      :: {Store.sid, Store.session}
    def get(conn, cookie, store) do
      with {:ok, {_ts, data}} <- Mnemonix.fetch(store, cookie) do
        {put(conn, cookie, data, store), data}
      else :error ->
        {nil, %{}}
      end
    end

    @spec put(Plug.Conn.t, Store.sid, any, GenServer.name)
      :: Store.cookie
    def put(conn, sid, data, store)

    def put(conn, nil, data, store) do
      put conn, make_sid(), data, store
    end

    def put(_conn, sid, data, store) when is_map data do
      with ^store <- Mnemonix.put(store, sid, {timestamp(), data}) do
        sid
      end
    end

    def put(conn, sid, data, store) do
      put conn, sid, Enum.into(data, %{}), store
    end

    @spec delete(Plug.Conn.t, Store.sid, GenServer.name)
      :: :ok
    def delete(conn, sid, store)

    def delete(_conn, sid, store) do
      with ^store <- Mnemonix.delete(store, sid) do
        :ok
      end
    end

    defp make_sid do
      @sid_bytes |> :crypto.strong_rand_bytes |> Base.encode64
    end

    defp timestamp() do
      :os.timestamp()
    end

  end
end
