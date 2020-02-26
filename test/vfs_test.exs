defmodule VFSTest do
  use ExUnit.Case
  doctest VFS

  setup_all do
    Hammox.protect(ConcreteAdapter, VFS.Adapter, read: 2, write: 3)
  end

  @adapters [VFS.Adapter.build_entry("test", ConcreteAdapter)]

  describe "read/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :read, fn "test://location", [] ->
        {:ok, []}
      end)

      assert {:ok, []} = VFS.read("test://location", [], @adapters)
    end

    test "inexistent adapter" do
      assert {:error, {VFS.Adapter.NotFoundError, [scheme: "dummy", uri: "dummy://location"]}} ==
               VFS.read("dummy://location", [], @adapters)
    end
  end

  describe "read!/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :read, fn "test://location", [] ->
        {:ok, []}
      end)

      assert [] = VFS.read!("test://location", [], @adapters)
    end

    test "inexistent adapter" do
      assert_raise VFS.Adapter.NotFoundError, fn ->
        VFS.write!("dummy://lala", [], [], @adapters)
      end
    end
  end

  describe "write/4" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :write, fn "test://location", _, _ ->
        :ok
      end)

      assert VFS.write("test://location", [], [], @adapters) == :ok
    end

    test "inexistent adapter" do
      uri = "dummy://location"

      assert {:error, {VFS.Adapter.NotFoundError, scheme: "dummy", uri: "dummy://location"}} ==
               VFS.write(uri, [], [], @adapters)
    end
  end

  describe "write!/4" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :write, fn "test://location_1", [], [] ->
        :ok
      end)

      assert VFS.write!("test://location_1", [], [], @adapters) == :ok
    end

    test "unhappy path" do
      Hammox.expect(ConcreteAdapter, :write, fn "test://location_1", _, _ ->
        {:error, {RuntimeError, message: "broken connection"}}
      end)

      assert_raise RuntimeError, "broken connection", fn ->
        VFS.write!("test://location_1", [], [], @adapters)
      end
    end

    test "inexistent adapter for uri" do
      uri = "dummy://location"

      assert_raise VFS.Adapter.NotFoundError,
                   fn ->
                     VFS.write!(uri, [], [], @adapters)
                   end
    end
  end

  describe "using" do
    defmodule DummyAdapter do
      use VFS.Adapter, :test

      def read(_, _), do: {:ok, []}
      def write(_, _, _), do: :ok
    end

    defmodule MyVFS do
      use VFS, :test

      adapter(DummyAdapter)
    end

    test "adapters/0" do
      assert MyVFS.adapters() == [
               %VFS.Adapter.Registry.Entry{module: DummyAdapter, scheme: "test"}
             ]
    end

    test "read/2" do
      assert MyVFS.read("test://location", []) == {:ok, []}
    end

    test "write/3" do
      assert MyVFS.write("test://location_1", [], []) == :ok
    end
  end
end
