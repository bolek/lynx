defmodule Lynx.Adapters.LocalFileSystemTest do
  use ExUnit.Case, async: true

  alias Lynx.Adapters.LocalFileSystem

  describe "read/2" do
    test "reading an existing file" do
      file_path = Path.expand("./test/data/a.txt")
      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.read(uri) ==
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
      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.read(uri) ==
               {:error, {Lynx.Exceptions.ObjectNotFound, uri}}
    end

    test "reading a directory" do
      file_path = Path.expand("./test/data")

      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.read(uri) ==
               {:error,
                {Lynx.Exceptions.ObjectNotReadable,
                 [uri: uri, details: "expected to read a data file, received a directory"]}}
    end
  end

  describe "write/2" do
    test "write to inexiestent file" do
      file_path = Path.expand("./test/tmp/foo/bar.txt")
      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.write(uri, ["foobar"]) == :ok
      assert File.read!(file_path) == "foobar"

      File.rm(file_path)
    end

    test "write to an existing file - overwrite" do
      file_path = Path.expand("./test/tmp/foo/bar.txt")
      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.write(uri, ["foobar"]) == :ok
      assert LocalFileSystem.write(uri, ["another foobar"]) == :ok
      assert File.read!(file_path) == "another foobar"

      File.rm(file_path)
    end

    test "write to directory" do
      file_path = Path.expand("./test")
      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.write(uri, ["foobar"]) ==
               {:error,
                {Lynx.Exceptions.ObjectNotWriteable,
                 [uri: uri, details: "cannot write to a directory"]}}
    end

    test "write to an invalid path" do
      file_path = Path.expand("./test/data/a.txt/b.txt")
      uri = URI.parse("file://" <> file_path)

      assert LocalFileSystem.write(uri, ["foobar"]) ==
               {Lynx.Exceptions.MalformedURI,
                [
                  uri: uri,
                  details: """
                  the subpath might contain a data file rather than a directory
                  example: /a.txt/b.txt
                  """
                ]}
    end
  end

  describe "delete/2" do
    test "delete an existing file" do
      file_path = Path.expand("./test/tmp/tmp4356.txt")
      uri = URI.parse("file://" <> file_path)
      LocalFileSystem.write(uri, ["tmp"])

      assert LocalFileSystem.delete(uri) == :ok
      refute File.exists?(file_path)
    end

    test "delete a directory" do
      dir_path = Path.expand("./test/tmp/foo_for_deletion")
      File.mkdir_p!(dir_path)
      uri = URI.parse("file://" <> dir_path)

      assert LocalFileSystem.delete(uri) == :ok

      File.rmdir(dir_path)
    end
  end
end
