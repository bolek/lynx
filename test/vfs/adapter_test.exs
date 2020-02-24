defmodule VFS.AdapterTest do
  use ExUnit.Case, async: true

  test "new/2" do
    assert VFS.Adapter.new("test", :dummy_module) == %VFS.Adapter{
             scheme: "test",
             module: :dummy_module
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
