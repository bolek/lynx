defmodule Lynx.Adapters.LocalFileSystemTest do
  use ExUnit.Case, async: true

  alias Lynx.Adapters.LocalFileSystem

  describe "read/2" do
    test "reading an existing file" do
      file_path = Path.expand("./test/data/a.txt")

      assert LocalFileSystem.read(file_path) ==
               {:ok,
                %File.Stream{
                  line_or_bytes: :bytes,
                  modes: [:raw, :read_ahead, :binary],
                  path: file_path,
                  raw: true
                }}
    end

    test "reading an inexistent file" do
      file_path = Path.expand("./test/data/boooom.txt")
      uri = "file:" <> file_path
      object = LocalFileSystem.new!(uri)

      assert LocalFileSystem.read(uri) ==
               {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}
    end

    test "reading a directory" do
      file_path = Path.expand("./test/data")
      uri = "file:" <> file_path
      object = LocalFileSystem.new!(uri)

      assert LocalFileSystem.read(uri) ==
               {:error,
                {Lynx.Exceptions.ObjectNotReadable,
                 [object: object, details: "expected to read a data file, received a directory"]}}
    end
  end

  describe "write/2" do
    test "write to inexiestent file" do
      file_path = Path.expand("./test/tmp/foo/bar.txt")

      assert LocalFileSystem.write(file_path, ["foobar"]) == :ok
      assert File.read!(file_path) == "foobar"
    after
      File.rm(Path.expand("./test/tmp/foo/bar.txt"))
    end

    test "write to an existing file - overwrite" do
      file_path = Path.expand("./test/tmp/foo/bar.txt")

      assert LocalFileSystem.write(file_path, ["foobar"]) == :ok
      assert LocalFileSystem.write(file_path, ["another foobar"]) == :ok
      assert File.read!(file_path) == "another foobar"
    after
      File.rm(Path.expand("./test/tmp/foo/bar.txt"))
    end

    test "write to directory" do
      file_path = Path.expand("./test")
      object = LocalFileSystem.new!("file:" <> file_path)

      assert LocalFileSystem.write(object, ["foobar"]) ==
               {:error,
                {Lynx.Exceptions.ObjectNotWriteable,
                 [object: object, details: "cannot write to a directory"]}}
    end

    test "write to an invalid path" do
      file_path = Path.expand("./test/data/a.txt/b.txt")
      object = LocalFileSystem.new!("file://" <> file_path)

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

      LocalFileSystem.write(file_path, ["tmp"])

      assert LocalFileSystem.delete(file_path) == :ok
      refute File.exists?(file_path)
    end

    test "delete a directory" do
      dir_path = Path.expand("./test/tmp/foo_for_deletion")
      File.mkdir_p!(dir_path)

      assert LocalFileSystem.delete(dir_path) == :ok
    after
      File.rmdir(Path.expand("./test/tmp/foo_for_deletion"))
    end
  end
end
