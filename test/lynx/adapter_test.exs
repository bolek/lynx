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

  describe "from/2" do
    test "object implements readable" do
      object = MyTestAdapter.new!("test://location")

      assert Lynx.Adapter.from(object) == {:ok, []}
    end

    test "object does not implement readable" do
      assert Lynx.Adapter.from(%{}) ==
               {:error, {Lynx.Exceptions.ObjectNotReadable, [object: %{}]}}
    end
  end

  describe "to/3" do
    test "object implements writable" do
      object = MyTestAdapter.new!("test://location")
      {:ok, stream} = Lynx.Adapter.to(["a"], object)
      assert Enumerable.impl_for(stream) != nil
    end

    test "object does not implement writable" do
      assert Lynx.Adapter.to(["a"], %{}) ==
               {:error, {Lynx.Exceptions.ObjectNotWritable, [object: %{}]}}
    end

    test "success from tuple" do
      object = MyTestAdapter.new!("test://location")
      {:ok, stream} = Lynx.Adapter.to({:ok, ["a"]}, object)

      assert Enumerable.impl_for(stream) != nil
    end

    test "error from tuple" do
      object = MyTestAdapter.new!("test://location")

      assert {:error, {Lynx.Exceptions.ObjectNotReadable, [object: %{}]}} =
               Lynx.Adapter.to(
                 {:error, {Lynx.Exceptions.ObjectNotReadable, [object: %{}]}},
                 object
               )
    end
  end
end
