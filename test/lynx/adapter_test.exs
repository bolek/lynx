defmodule Lynx.AdapterTest do
  use ExUnit.Case, async: true

  defmodule MyTestAdapter do
    use Lynx.Adapter, "test"

    def handle_read(_, _options \\ []), do: {:ok, []}
    def handle_write(_, _, _options \\ []), do: :ok
    def handle_delete(_, _options), do: :ok
    def init_object(object), do: {:ok, object}
  end

  describe "using" do
    test "scheme/0" do
      assert MyTestAdapter.scheme() == "test"
    end

    test "to_object/1" do
      assert MyTestAdapter.to_object("test://location") ==
               {:ok,
                %Lynx.Object{
                  adapter: MyTestAdapter,
                  extra: %{},
                  uri: URI.parse("test://location")
                }}
    end

    test "to_object!/1" do
      assert MyTestAdapter.to_object!("test://location") ==
               %Lynx.Object{
                 adapter: MyTestAdapter,
                 extra: %{},
                 uri: URI.parse("test://location")
               }
    end
  end

  test "read/2" do
    object = Lynx.Object.new!(URI.parse("test://location"), MyTestAdapter)
    assert Lynx.Adapter.read(object, []) == {:ok, []}
  end

  test "write/3" do
    object = Lynx.Object.new!(URI.parse("test://location"), MyTestAdapter)
    assert Lynx.Adapter.write(object, [], []) == :ok
  end

  test "delete/2" do
    object = Lynx.Object.new!(URI.parse("test://location"), MyTestAdapter)
    assert Lynx.Adapter.delete(object, []) == :ok
  end

  test "build_entry/2" do
    assert Lynx.Adapter.build_entry("test", MyTestAdapter) == %Lynx.Adapter.Registry.Entry{
             scheme: "test",
             module: MyTestAdapter
           }
  end

  setup_all do
    Hammox.protect(ConcreteAdapter, Lynx.Adapter, read: 2, write: 3, delete: 2, init_object: 1)
  end

  describe "behaviour" do
    test "read/2", %{read_2: read_2} do
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :read, fn %Lynx.Object{uri: %URI{}}, [] ->
        {:ok, []}
      end)

      object = Lynx.Object.new!(URI.parse("scheme://location"), ConcreteAdapter)

      assert {:ok, []} == read_2.(object, [])
    end

    test "write/3", %{write_3: write_3} do
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :write, fn _, [], [] ->
        :ok
      end)

      object = Lynx.Object.new!(URI.parse("scheme://location_2"), ConcreteAdapter)

      assert write_3.(object, [], []) == :ok
    end
  end
end
