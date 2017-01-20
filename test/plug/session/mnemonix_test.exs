defmodule Plug.Session.MNEMONIX.Test do
  use ExUnit.Case, async: true
  alias Plug.Session.MNEMONIX

  @mnemonix_store Mnemonix.Plug.Session

  setup do
    Mnemonix.Stores.Map.start_link(server: [name: @mnemonix_store])
    :ok
  end

  test "put and get session" do
    opts = MNEMONIX.init(store: @mnemonix_store)

    assert "foo" = MNEMONIX.put(%{}, "foo", %{foo: :bar}, opts)
    assert "bar" = MNEMONIX.put(%{}, "bar", %{bar: :foo}, opts)

    assert {"foo", %{foo: :bar}} = MNEMONIX.get(%{}, "foo", opts)
    assert {"bar", %{bar: :foo}} = MNEMONIX.get(%{}, "bar", opts)

    assert {nil, %{}} = MNEMONIX.get(%{}, "unknown", opts)
  end

  test "delete session" do
    opts = MNEMONIX.init(store: @mnemonix_store)

    MNEMONIX.put(%{}, "foo", %{foo: :bar}, opts)
    MNEMONIX.put(%{}, "bar", %{bar: :foo}, opts)
    MNEMONIX.delete(%{}, "foo", opts)

    assert {nil, %{}} = MNEMONIX.get(%{}, "foo", opts)
    assert {"bar", %{bar: :foo}} = MNEMONIX.get(%{}, "bar", opts)
  end

  test "generate new sid" do
    opts = MNEMONIX.init(store: @mnemonix_store)
    sid = MNEMONIX.put(%{}, nil, %{}, opts)
    assert byte_size(sid) == 128
  end

  test "invalidate sid if unknown" do
    opts = MNEMONIX.init(store: @mnemonix_store)
    assert {nil, %{}} = MNEMONIX.get(%{}, "unknown_sid", opts)
  end
end
