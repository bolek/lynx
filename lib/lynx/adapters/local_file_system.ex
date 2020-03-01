defmodule Lynx.Adapters.LocalFileSystem do
  use Lynx.Adapter, :file

  @impl true
  def read("file://" <> path, options \\ []) do
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
  def write("file://" <> path, stream, _options \\ []) do
    dir_path = Path.dirname(path)

    with :ok <- File.mkdir_p(dir_path) do
      stream
      |> Stream.into(stream!(path, modes: [:write, :utf8]))
      |> Stream.run()
    else
      {:error, reason} ->
        {:error,
         {File.Error,
          reason: reason, action: "make directory (with -p)", path: IO.chardata_to_string(path)}}
    end
  end

  @impl true
  def delete("file://" <> path, _options \\ []) do
    File.rm(path)
  end

  def stream!(path, options \\ []) do
    modes = Keyword.get(options, :modes, [])
    line_or_bytes = Keyword.get(options, :stream_mode, :line)

    File.stream!(path, modes, line_or_bytes)
  end
end
