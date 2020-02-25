defmodule VFS.AdapterTest do
  use ExUnit.Case, async: true

  defmodule MyTestAdapter do
    use VFS.Adapter, "test"

    def get(_), do: {:ok, []}
    def put(_, _), do: {:ok, "test://to_location"}
  end

  describe "using" do
    test "scheme/0" do
      assert MyTestAdapter.scheme() == "test"
    end
  end

  test "get/2" do
    assert VFS.Adapter.get(MyTestAdapter, "test://location") == {:ok, []}
  end

  test "put/3" do
    assert VFS.Adapter.put(MyTestAdapter, [], "test://to_location") ==
             {:ok, "test://to_location"}
  end

  test "build_entry/2" do
    assert VFS.Adapter.build_entry("test", MyTestAdapter) == %VFS.Adapter.Registry.Entry{
             scheme: "test",
             module: MyTestAdapter
           }
  end

  setup_all do
    Hammox.protect(ConcreteAdapter, VFS.Adapter, get: 1, put: 2)
  end

  describe "behaviour" do
    test "get/1", %{get_1: get_1} do
      Hammox.expect(ConcreteAdapter, :get, fn "scheme://location" ->
        {:ok, []}
      end)

      assert {:ok, []} == get_1.("scheme://location")
    end

    test "pull/2", %{put_2: put_2} do
      Hammox.expect(ConcreteAdapter, :put, fn [], "scheme://location_2" ->
        {:ok, "scheme://location_2"}
      end)

      assert {:ok, "scheme://location_2"} == put_2.([], "scheme://location_2")
    end
  end
end
