defmodule VFS.AdapterTest do
  use ExUnit.Case, async: true

  test "build_entry/2" do
    assert VFS.Adapter.build_entry("test", MyTestAdapter) == %VFS.Adapter.Registry.Entry{
             scheme: "test",
             module: MyTestAdapter
           }
  end

  describe "using" do
    defmodule MyTestAdapter do
      use VFS.Adapter, "test"

      def get(_), do: raise("not implemented")
      def put(_, _), do: raise("not implemented")
    end

    test "scheme/0" do
      assert MyTestAdapter.scheme() == "test"
    end
  end
end
