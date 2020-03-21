defmodule Lynx.AdapterTest do
  use ExUnit.Case, async: true

  describe "using" do
    test "scheme/0" do
      assert MyTestAdapter.scheme() == "test"
    end

    test "new!/1" do
      assert MyTestAdapter.new!("test://location") ==
               %MyTestAdapter{
                 uri: URI.parse("test://location")
               }
    end
  end

  test "read/2" do
    object = MyTestAdapter.new!("test://location")
    assert Lynx.Adapter.read(object, []) == {:ok, []}
  end

  test "write/3" do
    object = MyTestAdapter.new!("test://location")
    assert Lynx.Adapter.write(object, [], []) == :ok
  end

  test "delete/2" do
    object = MyTestAdapter.new!("test://location")
    assert Lynx.Adapter.delete(object, []) == :ok
  end

  test "build_entry/2" do
    assert Lynx.Adapter.build_entry("test", MyTestAdapter) == %Lynx.Adapter.Registry.Entry{
             scheme: "test",
             module: MyTestAdapter
           }
  end

  setup_all do
    Hammox.protect(ConcreteAdapter, Lynx.Adapter,
      handle_read: 2,
      handle_write: 3,
      handle_delete: 2
    )
  end

  describe "behaviour" do
    test "read/2", %{handle_read_2: read_2} do
      Hammox.expect(ConcreteAdapter, :new, fn object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :handle_read, fn "scheme://location", [] ->
        {:ok, []}
      end)

      {:ok, object} = ConcreteAdapter.new("scheme://location")

      assert {:ok, []} == read_2.(object, [])
    end

    test "write/3", %{handle_write_3: write_3} do
      Hammox.expect(ConcreteAdapter, :new, fn object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :handle_write, fn _, [], [] ->
        :ok
      end)

      {:ok, object} = ConcreteAdapter.new("scheme://location_2")

      assert write_3.(object, [], []) == :ok
    end
  end
end
