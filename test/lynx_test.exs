defmodule LynxTest do
  use ExUnit.Case
  doctest Lynx

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
