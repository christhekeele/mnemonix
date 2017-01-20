if Code.ensure_loaded?(Plug) do
  defmodule Plug.Session.MNEMONIX do
    @moduledoc """
    Stores the session in a `Mnemonix.Store.Server`.

    This store does not create the Mnemonix store; it expects that a reference to an existing store server is passed in as an argument.

    We recommend carefully choosing the store type for production usage. Consider: persistence, cleanup, and cross-node availability.

    ## Options
      * `:store` - `t:Mnemonix.store/0` reference (required)

    ## Examples

        # Start a named store when the application starts
        Mnemonix.Stores.Map.start_link(server: [name: My.Plug.Session])

        # Use the session plug with the table name
        plug Plug.Session, store: :mnemonix, key: "sid", store: My.Plug.Session
    """

    @behaviour Plug.Session.Store
    alias Plug.Session.Store

    @sid_bytes 96

    @spec init(Plug.opts) :: Mnemonix.store
    def init(opts) do
      Keyword.fetch!(opts, :store)
    end

    @spec get(Plug.Conn.t, Store.sid, Mnemonix.store)
      :: {Store.sid, Store.session}
    def get(conn, sid, store)

    def get(_conn, sid, store) do
      case Mnemonix.fetch(store, sid) do
        {:ok, data} -> {sid, data}
        :error      -> {nil, %{}}
      end
    end

    @spec put(Plug.Conn.t, Store.sid, Store.session, Mnemonix.store)
      :: Store.sid
    def put(conn, sid, data, store)

    def put(conn, nil, data, store) do
      put conn, make_sid(), data, store
    end

    def put(_conn, sid, data, store) when is_map data do
      Mnemonix.put(store, sid, data)
      sid
    end

    def put(conn, sid, data, store) do
      put conn, sid, Enum.into(data, %{}), store
    end

    @spec delete(Plug.Conn.t, Store.sid, Plug.opts) :: :ok
    def delete(conn, sid, store)

    def delete(_conn, sid, store) do
      Mnemonix.delete(store, sid)
      :ok
    end

    defp make_sid() do
      @sid_bytes |> :crypto.strong_rand_bytes |> Base.encode64
    end

  end
end
