defmodule VFSTest do
  use ExUnit.Case
  doctest VFS

  setup_all do
    Hammox.protect(ConcreteAdapter, VFS.Adapter, get: 1, put: 2)
  end

  @adapters [VFS.Adapter.build_entry("test", ConcreteAdapter)]

  describe "get/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :get, fn "test://location" ->
        {:ok, []}
      end)

      assert {:ok, []} = VFS.get("test://location", @adapters)
    end

    test "inexistent adapter" do
      assert {:error, {VFS.Adapter.NotFoundError, [scheme: "dummy", uri: "dummy://location"]}} ==
               VFS.get("dummy://location", @adapters)
    end
  end

  describe "get!/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :get, fn "test://location" ->
        {:ok, []}
      end)

      assert [] = VFS.get!("test://location", @adapters)
    end

    test "inexistent adapter" do
      assert_raise VFS.Adapter.NotFoundError, fn ->
        VFS.put!("dummy://lala", "baba://location", @adapters)
      end
    end
  end

  describe "put/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :put, fn [], "test://location_2" ->
        {:ok, "test://location_2"}
      end)

      Hammox.expect(ConcreteAdapter, :get, fn "test://location_1" ->
        {:ok, []}
      end)

      assert VFS.put("test://location_1", "test://location_2", @adapters) ==
               {:ok, "test://location_2"}
    end

    test "inexistent adapter" do
      from_uri = "dummy://location"
      to_uri = "test://location"

      assert {:error, {VFS.Adapter.NotFoundError, scheme: "dummy", uri: "dummy://location"}} ==
               VFS.put(from_uri, to_uri, @adapters)
    end
  end

  describe "put!/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :get, fn "test://location_1" ->
        {:ok, []}
      end)

      Hammox.expect(ConcreteAdapter, :put, fn [], "test://location_2" ->
        {:ok, "test://location_2"}
      end)

      assert VFS.put!("test://location_1", "test://location_2", @adapters) ==
               "test://location_2"
    end

    test "unhappy path" do
      Hammox.expect(ConcreteAdapter, :get, fn "test://location_1" ->
        {:error, {RuntimeError, message: "broken connection"}}
      end)

      assert_raise RuntimeError, "broken connection", fn ->
        VFS.put!("test://location_1", "test://location_2", @adapters)
      end
    end

    test "inexistent adapter for from_uri" do
      from_uri = "dummy://location"
      to_uri = "test://location"

      assert_raise VFS.Adapter.NotFoundError,
                   fn ->
                     VFS.put!(from_uri, to_uri, @adapters)
                   end
    end

    test "inexistent adapter for to_uri" do
      from_uri = "test://location"
      to_uri = "dummy://location"

      Hammox.expect(ConcreteAdapter, :get, fn "test://location" ->
        {:ok, []}
      end)

      assert_raise VFS.Adapter.NotFoundError,
                   fn ->
                     VFS.put!(from_uri, to_uri, @adapters)
                   end
    end
  end

  describe "using" do
    defmodule DummyAdapter do
      use VFS.Adapter, :test

      def get(_), do: {:ok, []}
      def put(_, to_uri), do: {:ok, to_uri}
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

    test "get/1" do
      assert MyVFS.get("test://location") == {:ok, []}
    end

    test "put/1" do
      assert MyVFS.put("test://location_1", "test://location_2") == {:ok, "test://location_2"}
    end
  end
end
