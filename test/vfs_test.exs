defmodule VFSTest do
  use ExUnit.Case
  doctest VFS

  describe "get/2" do
    @adapters [VFS.Adapter.new("test", VFSTestAdapter)]

    test "happy path" do
      {:ok, _} = VFS.get({"test", [1, 2, 3]}, @adapters)
    end

    test "inexistent adapter" do
      assert_raise RuntimeError, "Adapter for scheme \"baba\" was not found.", fn ->
        VFS.get({"baba", [1, 2, 3]}, @adapters)
      end
    end
  end

  describe "put/2" do
    @adapters [VFS.Adapter.new("test", VFSTestAdapter)]

    test "happy path" do
      assert VFS.put({"test", [1, 2, 3]}, {"test", []}, @adapters) == {:ok, {"test", [1, 2, 3]}}
    end

    test "inexistent adapter" do
      assert_raise RuntimeError, "Adapter for scheme \"baba\" was not found.", fn ->
        assert VFS.put({"baba", [1, 2, 3]}, {"test", []}, @adapters) == {:ok, {"test", [1, 2, 3]}}
      end
    end
  end

  describe "using" do
    defmodule MyVFS do
      use VFS

      adapter(VFSTestAdapter)
    end

    test "adapters" do
      assert MyVFS.adapters() == [
               %VFS.Adapter{module: VFSTestAdapter, scheme: "test"}
             ]
    end
  end

  describe "between two resources using different adapters" do
    @adapters [
      VFS.Adapter.new("test", VFSTestAdapter),
      VFS.Adapter.new("file", VFS.Adapters.LocalFileSystem)
    ]

    test "happy path" do
      assert VFS.put(
               "file://" <> Path.expand("./test/data/a.txt"),
               {"test", []},
               @adapters
             ) ==
               {:ok, {"test", ["foo"]}}
    end
  end
end
