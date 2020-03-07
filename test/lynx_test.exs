defmodule LynxTest do
  use ExUnit.Case
  doctest Lynx

  setup_all do
    Hammox.protect(ConcreteAdapter, Lynx.Adapter, read: 2, write: 3, init_object: 1)
  end

  @adapters [Lynx.Adapter.build_entry("test", ConcreteAdapter)]

  describe "read/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :read, fn %Lynx.Object{}, [] ->
        {:ok, []}
      end)

      assert {:ok, []} = Lynx.read("test://location", [], @adapters)
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

  describe "read!/2" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :read, fn %Lynx.Object{}, [] ->
        {:ok, []}
      end)

      assert [] = Lynx.read!("test://location", [], @adapters)
    end

    test "inexistent adapter" do
      assert_raise Lynx.Adapter.NotFoundError, fn ->
        Lynx.write!("dummy://lala", [], [], @adapters)
      end
    end
  end

  describe "write/4" do
    test "happy path" do
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :write, fn %Lynx.Object{}, _, _ ->
        :ok
      end)

      assert Lynx.write("test://location", [], [], @adapters) == :ok
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
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :write, fn %Lynx.Object{}, [], [] ->
        :ok
      end)

      assert Lynx.write!("test://location_1", [], [], @adapters) == :ok
    end

    test "unhappy path" do
      Hammox.expect(ConcreteAdapter, :init_object, fn %Lynx.Object{} = object -> {:ok, object} end)

      Hammox.expect(ConcreteAdapter, :write, fn %Lynx.Object{}, _, _ ->
        {:error, {RuntimeError, message: "broken connection"}}
      end)

      assert_raise RuntimeError, "broken connection", fn ->
        Lynx.write!("test://location_1", [], [], @adapters)
      end
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
    defmodule DummyAdapter do
      use Lynx.Adapter, :test

      def read(_, _), do: {:ok, []}
      def write(_, _, _), do: :ok
      def delete(_, _), do: :ok
      def init_object(object), do: {:ok, Lynx.Object.put_extra(object, %{a: :b})}
    end

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
      assert MyLynx.read(URI.parse("test://location"), []) == {:ok, []}
    end

    test "write/3" do
      assert MyLynx.write(URI.parse("test://location_1"), [], []) == :ok
    end

    test "delete/3" do
      assert MyLynx.delete(URI.parse("test://location_1"), []) == :ok
    end
  end
end
