defmodule Lynx.Adapters.LocalFileSystemTest do
  use ExUnit.Case, async: true

  alias Lynx.Adapters.LocalFileSystem

  describe "implements Lynx.Adapter.Readable" do
    test "reading an existing file" do
      file_path = Path.expand("./test/data/a.txt")
      object = LocalFileSystem.new!(file_path)

      assert Lynx.Adapter.Readable.from(object) ==
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

      assert Lynx.Adapter.Readable.from(object) ==
               {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}
    end

    test "reading a directory" do
      file_path = Path.expand("./test/data")
      uri = "file:" <> file_path
      object = LocalFileSystem.new!(uri)

      assert Lynx.Adapter.Readable.from(object) ==
               {:error,
                {Lynx.Exceptions.ObjectNotReadable,
                 [object: object, details: "expected to read a data file, received a directory"]}}
    end
  end

  describe "implements Lynx.Adapter.Writable" do
    test "write to inexistent file" do
      file_path = Path.expand("./test/data/foobar.txt")
      object = LocalFileSystem.new!(file_path)

      assert {:ok, stream} = Lynx.Adapter.Writable.to(object)
      assert Collectable.impl_for(stream) != nil
    end

    test "write to an existing file - overwrite" do
      file_path = Path.expand("./test/data/a.txt")
      object = LocalFileSystem.new!(file_path)

      assert {:ok, stream} = Lynx.Adapter.Writable.to(object)
      assert Collectable.impl_for(stream) != nil
    end

    test "write to an existing file with fail flag" do
      file_path = Path.expand("./test/data/a.txt")
      object = LocalFileSystem.new!(file_path)

      assert Lynx.Adapter.Writable.to(object, file_exists: :fail) ==
               {:error, {Lynx.Exceptions.ObjectExists, [object: object]}}
    end

    test "write to directory" do
      file_path = Path.expand("./test/data")
      object = LocalFileSystem.new!(file_path)

      assert Lynx.Adapter.Writable.to(object) ==
               {:error,
                {Lynx.Exceptions.ObjectNotWriteable,
                 [object: object, details: "cannot write to a directory"]}}
    end

    test "write to an invalid path" do
      file_path = Path.expand("./test/data/a.txt/b.txt")
      object = LocalFileSystem.new!(file_path)

      assert Lynx.Adapter.Writable.to(object) ==
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

  # describe "write/2" do

  # end

  describe "delete/2" do
    test "delete an existing file" do
      file_path = Path.expand("./test/tmp/tmp4356.txt")
      File.write(file_path, "tmp")

      object = LocalFileSystem.new!(file_path)

      assert LocalFileSystem.delete(object) == :ok
      refute File.exists?(file_path)
    end

    test "delete a directory" do
      dir_path = Path.expand("./test/tmp/foo_for_deletion")
      File.mkdir_p!(dir_path)

      object = LocalFileSystem.new!(dir_path)

      assert LocalFileSystem.delete(object) == :ok
    after
      File.rmdir(Path.expand("./test/tmp/foo_for_deletion"))
    end
  end
end
