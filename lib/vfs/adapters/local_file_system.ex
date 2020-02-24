defmodule VFS.Adapters.LocalFileSystem do
  use VFS.Adapter, :file

  @impl true
  def get("file://" <> path, options \\ []) do
    cond do
      !File.exists?(path) ->
        {:error, :not_exists}

      File.dir?(path) ->
        {:error, :not_a_file}

      true ->
        {:ok, stream!(path, options)}
    end
  end

  @impl true
  def put(stream, "file://" <> path = to, _options \\ []) do
    dir_path = Path.dirname(path)

    with :ok <- File.mkdir_p(dir_path) do
      stream
      |> Stream.into(stream!(path, modes: [:write, :utf8]))
      |> Stream.run()
    end

    {:ok, to}
  end

  def stream!(path, options \\ []) do
    modes = Keyword.get(options, :modes, [])
    line_or_bytes = Keyword.get(options, :stream_mode, :line)

    File.stream!(path, modes, line_or_bytes)
  end
end
