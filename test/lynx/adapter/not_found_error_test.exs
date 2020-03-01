defmodule Lynx.Adapter.NotFoundErrorTest do
  use ExUnit.Case, async: true

  test "message/1" do
    assert Lynx.Adapter.NotFoundError.message(%{uri: URI.parse("test://location")}) ==
             "could not find an adapter implementation for scheme \"test\" in \"test://location\""
  end
end
