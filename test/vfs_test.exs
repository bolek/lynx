defmodule VFSTest do
  use ExUnit.Case
  doctest VFS

  test "greets the world" do
    assert VFS.hello() == :world
  end
end
