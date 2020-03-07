defmodule Lynx.Adapters.LocalFileSystemTest do
  use ExUnit.Case, async: true

  alias Lynx.Adapters.LocalFileSystem

  describe "read/2" do
    test "reading an existing file" do
      file_path = Path.expand("./test/data/a.txt")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.read(object) ==
               {:ok,
                %File.Stream{
                  line_or_bytes: :line,
                  modes: [:raw, :read_ahead, :binary],
                  path: file_path,
                  raw: true
                }}
    end

    test "reading an inexistent file" do
      file_path = Path.expand("./test/data/boooom.txt")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.read(object) ==
               {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}
    end

    test "reading a directory" do
      file_path = Path.expand("./test/data")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.read(object) ==
               {:error,
                {Lynx.Exceptions.ObjectNotReadable,
                 [object: object, details: "expected to read a data file, received a directory"]}}
    end
  end

  describe "write/2" do
    test "write to inexiestent file" do
      file_path = Path.expand("./test/tmp/foo/bar.txt")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.write(object, ["foobar"]) == :ok
      assert File.read!(file_path) == "foobar"

      File.rm(file_path)
    end

    test "write to an existing file - overwrite" do
      file_path = Path.expand("./test/tmp/foo/bar.txt")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.write(object, ["foobar"]) == :ok
      assert LocalFileSystem.write(object, ["another foobar"]) == :ok
      assert File.read!(file_path) == "another foobar"

      File.rm(file_path)
    end

    test "write to directory" do
      file_path = Path.expand("./test")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.write(object, ["foobar"]) ==
               {:error,
                {Lynx.Exceptions.ObjectNotWriteable,
                 [object: object, details: "cannot write to a directory"]}}
    end

    test "write to an invalid path" do
      file_path = Path.expand("./test/data/a.txt/b.txt")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.write(object, ["foobar"]) ==
               {:error,
                {Lynx.Exceptions.MalformedURI,
                 [
                   object: object,
                   details: """
                   the subpath might contain a data file rather than a directory
                   example: /a.txt/b.txt
                   """
                 ]}}
    end
  end

  describe "delete/2" do
    test "delete an existing file" do
      file_path = Path.expand("./test/tmp/tmp4356.txt")
      object = LocalFileSystem.to_object!("file://" <> file_path)

      LocalFileSystem.write(object, ["tmp"])

      object = LocalFileSystem.to_object!("file://" <> file_path)

      assert LocalFileSystem.delete(object) == :ok
      refute File.exists?(file_path)
    end

    test "delete a directory" do
      dir_path = Path.expand("./test/tmp/foo_for_deletion")
      File.mkdir_p!(dir_path)
      object = LocalFileSystem.to_object!("file://" <> dir_path)

      assert LocalFileSystem.delete(object) == :ok

      File.rmdir(dir_path)
    end
  end
end
