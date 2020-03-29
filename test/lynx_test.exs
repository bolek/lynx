defmodule LynxTest do
  use ExUnit.Case
  doctest Lynx

  describe "run/1" do
    test "success tuple" do
      stream = Stream.map(1..3, &(&1 * 2))

      assert Lynx.run({:ok, stream}) == :ok
    end

    test "error tuple" do
      assert Lynx.run({:error, "error"}) == {:error, "error"}
    end

    test "just stream" do
      stream = Stream.map(1..3, &(&1 * 2))

      assert Lynx.run(stream) == :ok
    end
  end

  describe "using" do
    defmodule MyLynx do
      use Lynx, :test

      adapter(MyTestAdapter)
    end

    test "adapters/0" do
      assert MyLynx.adapters() == [
               %Lynx.Adapter.Registry.Entry{module: MyTestAdapter, scheme: "test"}
             ]
    end

    test "new/1" do
      assert {:ok, %MyTestAdapter{uri: %URI{}}} = MyLynx.new("test://location")
    end

    test "new!/1" do
      assert %MyTestAdapter{uri: %URI{}} = MyLynx.new!("test://location")
    end
  end
end
