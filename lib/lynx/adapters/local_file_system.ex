defmodule Lynx.Adapters.LocalFileSystem do
  use Lynx.Adapter, :file

  defmodule Extra do
    defstruct [:is_dir?, :exists?]

    @type t :: %__MODULE__{is_dir?: boolean, exists?: boolean}

    @spec new(%{path: binary}) :: t
    def new(%{path: path}) do
      %__MODULE__{
        is_dir?: File.dir?(path),
        exists?: File.exists?(path)
      }
    end
  end

  @spec extra(%{path: binary}) :: {:ok, Extra.t()}
  def extra(uri) do
    {:ok, Extra.new(uri)}
  end

  @impl true
  def read(%URI{path: path} = uri, options \\ []) do
    cond do
      !File.exists?(path) ->
        {:error, {Lynx.Exceptions.ObjectNotFound, uri}}

      File.dir?(path) ->
        {:error,
         {Lynx.Exceptions.ObjectNotReadable,
          [uri: uri, details: "expected to read a data file, received a directory"]}}

      true ->
        {:ok, stream!(path, options)}
    end
  end

  @impl true
  def write(%URI{path: path} = uri, stream, _options \\ []) do
    cond do
      File.dir?(path) ->
        {:error,
         {Lynx.Exceptions.ObjectNotWriteable, [uri: uri, details: "cannot write to a directory"]}}

      File.exists?(path) ->
        write_from_stream(stream, path)

      true ->
        dir_path = Path.dirname(path)

        with :ok <- File.mkdir_p(dir_path) do
          write_from_stream(stream, path)
        else
          {:error, :eexist} ->
            {Lynx.Exceptions.MalformedURI,
             [
               uri: uri,
               details: """
               the subpath might contain a data file rather than a directory
               example: /a.txt/b.txt
               """
             ]}

          {:error, reason} ->
            {:error,
             {File.Error,
              reason: reason,
              action: "make directory (with -p)",
              path: IO.chardata_to_string(path)}}
        end
    end
  end

  defp write_from_stream(stream, path) do
    stream
    |> Stream.into(stream!(path, modes: [:write, :utf8]))
    |> Stream.run()
  end

  @impl true
  def delete(%URI{path: path}, _options \\ []) do
    cond do
      File.dir?(path) ->
        with {:ok, _} <- File.rm_rf(path) do
          :ok
        end

      true ->
        File.rm(path)
    end
  end

  def stream!(path, options \\ []) do
    modes = Keyword.get(options, :modes, [])
    line_or_bytes = Keyword.get(options, :stream_mode, :line)

    File.stream!(path, modes, line_or_bytes)
  end
end
