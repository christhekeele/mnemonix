if Code.ensure_loaded?(Plug) do
  defmodule Plug.Session.MNEMONIX do
    @moduledoc """
    Stores the session in a store.

    This store does not create the Mnemonix store; it expects that a reference
    to an existing store server is passed in as an argument.

    We recommend carefully choosing the store type for production usage.
    Consider: persistence, cleanup, and cross-node availability (or lack thereof).

    ## Options
      * `:store` - `t:Mnemonix.store/0` reference (required)

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
      :: Plug.opts | no_return
    def init(opts) do
      if Keyword.has_key?(opts, :mnemonix) do
        opts
      else
        raise Exception, message: "Mnemonix session plug must be given a `:mnemonix` reference in options"
      end
    end

    @spec get(Plug.Conn.t, Store.cookie, Plug.opts)
      :: {Store.sid, Store.session}
    def get(conn, cookie, store)

    def get(_conn, sid, opts) do
      case Mnemonix.fetch(Keyword.fetch!(opts, :mnemonix), sid) do
        {:ok, data} -> {sid, data}
        :error      -> {nil, %{}}
      end
    end

    @spec put(Plug.Conn.t, Store.sid, any, Plug.opts)
      :: Store.cookie
    def put(conn, sid, data, opts)

    def put(conn, nil, data, opts) do
      put conn, make_sid(), data, opts
    end

    def put(_conn, sid, data, opts) when is_map data do
      with :ok <- Mnemonix.put(Keyword.fetch!(opts, :mnemonix), sid, data) do
        sid
      end
    end

    def put(conn, sid, data, opts) do
      put conn, sid, Enum.into(data, %{}), opts
    end

    @spec delete(Plug.Conn.t, Store.sid, Plug.opts)
      :: :ok
    def delete(conn, sid, opts)

    def delete(_conn, sid, opts) do
      with :ok <- Mnemonix.delete(Keyword.fetch!(opts, :mnemonix), sid) do
        :ok
      end
    end

    defp make_sid() do
      @sid_bytes |> :crypto.strong_rand_bytes |> Base.encode64
    end

  end
end
