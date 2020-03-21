defmodule LynxTest do
  use ExUnit.Case
  doctest Lynx

  defmodule DummyAdapter do
    use Lynx.Adapter, scheme: :test

    defstruct [:uri]
    def new("bad"), do: {:error, {Lynx.Exceptions.MalformedURI, uri: "bad"}}
    def new(uri), do: {:ok, %__MODULE__{uri: URI.parse(uri)}}

    def handle_read(_, _), do: {:ok, []}
    def handle_write(_, _, _), do: :ok
    def handle_delete(_, _), do: :ok
  end

  @adapters [Lynx.Adapter.build_entry("test", DummyAdapter)]

  describe "read/2" do
    test "happy path" do
      object = DummyAdapter.new!("test://location")
      assert {:ok, []} = Lynx.read(object, [])
    end
  end

  describe "read/3" do
    test "happy path" do
      assert {:ok, []} = Lynx.read("test://location", [], @adapters)
    end

    test "using specific adapter" do
      assert {:ok, []} = Lynx.read("test://location", [], DummyAdapter)
    end

    test "inexistent adapter" do
      assert {:error,
              {Lynx.Adapter.NotFoundError,
               [
                 uri: %URI{
                   authority: "location",
                   fragment: nil,
                   host: "location",
                   path: nil,
                   port: nil,
                   query: nil,
                   scheme: "dummy",
                   userinfo: nil
                 }
               ]}} ==
               Lynx.read("dummy://location", [], @adapters)
    end
  end

  describe "read!/3" do
    test "happy path" do
      assert [] = Lynx.read!("test://location", [], @adapters)
    end

    test "using specific adapter" do
      assert [] = Lynx.read!("test://location", [], DummyAdapter)
    end

    test "inexistent adapter" do
      assert_raise Lynx.Adapter.NotFoundError, fn ->
        Lynx.write!("dummy://lala", [], [], @adapters)
      end
    end
  end

  describe "write/4" do
    test "happy path" do
      assert Lynx.write("test://location", [], [], @adapters) == :ok
    end

    test "using specific adapter" do
      assert Lynx.write("test://location", [], [], DummyAdapter) == :ok
    end

    test "inexistent adapter" do
      uri = "dummy://location"

      assert {:error,
              {Lynx.Adapter.NotFoundError,
               uri: %URI{
                 authority: "location",
                 fragment: nil,
                 host: "location",
                 path: nil,
                 port: nil,
                 query: nil,
                 scheme: "dummy",
                 userinfo: nil
               }}} ==
               Lynx.write(uri, [], [], @adapters)
    end
  end

  describe "write!/4" do
    test "happy path" do
      assert Lynx.write!("test://location_1", [], [], @adapters) == :ok
    end

    test "using specific adapter" do
      assert Lynx.write!("test://location_1", [], [], DummyAdapter) == :ok
    end

    test "inexistent adapter for uri" do
      uri = "dummy://location"

      assert_raise Lynx.Adapter.NotFoundError,
                   fn ->
                     Lynx.write!(uri, [], [], @adapters)
                   end
    end
  end

  describe "using" do
    defmodule MyLynx do
      use Lynx, :test

      adapter(DummyAdapter)
    end

    test "adapters/0" do
      assert MyLynx.adapters() == [
               %Lynx.Adapter.Registry.Entry{module: DummyAdapter, scheme: "test"}
             ]
    end

    test "read/2" do
      assert MyLynx.read("test://location", []) == {:ok, []}
    end

    test "write/3" do
      assert MyLynx.write("test://location_1", [], []) == :ok
    end

    test "delete/3" do
      assert MyLynx.delete("test://location_1", []) == :ok
    end
  end
end
