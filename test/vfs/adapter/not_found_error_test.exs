defmodule VFS.Adapter.NotFoundErrorTest do
  use ExUnit.Case, async: true

  test "message/1" do
    assert VFS.Adapter.NotFoundError.message(%{scheme: "test", uri: "test://location"}) ==
             "could not find an adapter implementation for scheme \"test\" in \"test://location\""
  end
end
