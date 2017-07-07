defmodule Mnemonix.Stores.Elastix.Test do
  use Mnemonix.Test.Case, async: true
  import Elastic.TestHelpers

  @moduletag :elastic

  setup_all do
    options = [store: [index: "mnemonix_test"] ]
    {:ok, store} = Mnemonix.Stores.Elastix.start_link(options)

    [store: store]
  end

  test "put & fetch a binary value", context do
    Mnemonix.put(context[:store], "foo_binary", "bar")
    assert wait_for_value("foo_binary", "bar", context) == "bar"
  end

  test "put & fetch a map", context do
    val = %{"foo" => "bar", "baz" => 1}
    Mnemonix.put(context[:store], "foo_map", val)
    assert wait_for_value("foo_map", val, context) == val
  end

  test "put & fetch a list", context do
    Mnemonix.put(context[:store], "foo_list", [1,2,4])
    assert wait_for_value("foo_list", [1,2,4], context) == [1,2,4]
  end

  test "delete", context do
    Mnemonix.put(context[:store], "foo_delete", "I'm still here!")
    assert wait_for_value("foo_delete", "I'm still here!", context) == "I'm still here!"

    Mnemonix.delete(context[:store], "foo_delete")
    assert wait_for_value("foo_delete", nil, context) == nil
  end

end
