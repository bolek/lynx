defmodule VFS.AdapterTest do
  use ExUnit.Case, async: true

  defmodule MyTestAdapter do
    use VFS.Adapter, "test"

    def read(_, _options \\ []), do: {:ok, []}
    def write(_, _, _options \\ []), do: :ok
  end

  describe "using" do
    test "scheme/0" do
      assert MyTestAdapter.scheme() == "test"
    end
  end

  test "read/3" do
    assert VFS.Adapter.read(MyTestAdapter, "test://location") == {:ok, []}
  end

  test "write/3" do
    assert VFS.Adapter.write(MyTestAdapter, "test://to_location", []) == :ok
  end

  test "build_entry/2" do
    assert VFS.Adapter.build_entry("test", MyTestAdapter) == %VFS.Adapter.Registry.Entry{
             scheme: "test",
             module: MyTestAdapter
           }
  end

  setup_all do
    Hammox.protect(ConcreteAdapter, VFS.Adapter, read: 2, write: 3)
  end

  describe "behaviour" do
    test "read/2", %{read_2: read_2} do
      Hammox.expect(ConcreteAdapter, :read, fn "scheme://location", [] ->
        {:ok, []}
      end)

      assert {:ok, []} == read_2.("scheme://location", [])
    end

    test "write/3", %{write_3: write_3} do
      Hammox.expect(ConcreteAdapter, :write, fn "scheme://location_2", [], [] ->
        :ok
      end)

      assert write_3.("scheme://location_2", [], []) == :ok
    end
  end
end
