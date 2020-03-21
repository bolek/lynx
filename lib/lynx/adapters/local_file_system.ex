defmodule Lynx.Adapters.LocalFileSystem do
  alias __MODULE__
  use Lynx.Adapter, scheme: :file

  defstruct [:is_dir?, :exists?, :uri]

  @type t :: %LocalFileSystem{is_dir?: boolean, exists?: boolean, uri: URI.t()}

  @impl true
  def new(uri) do
    parsed_uri = URI.parse(uri)

    {:ok,
     %__MODULE__{
       uri: parsed_uri,
       is_dir?: File.dir?(parsed_uri.path),
       exists?: File.exists?(parsed_uri.path)
     }}
  end

  @impl true
  @spec handle_read(t, keyword) ::
          {:ok, File.Stream.t()}
          | {:error,
             {Lynx.Exceptions.ObjectNotFound, keyword}
             | {Lynx.Exceptions.ObjectNotReadable, keyword}}
  def handle_read(%LocalFileSystem{} = object, options) do
    cond do
      !exists?(object) ->
        {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}

      is_dir?(object) ->
        {:error,
         {Lynx.Exceptions.ObjectNotReadable,
          [object: object, details: "expected to read a data file, received a directory"]}}

      true ->
        {:ok, stream!(object, options)}
    end
  end

  @impl true
  @spec handle_write(t(), Lynx.stream(), keyword) ::
          :ok
          | {:error,
             {File.Error, keyword}
             | {Lynx.Exceptions.MalformedURI, keyword}
             | {Lynx.Exceptions.ObjectNotWriteable, keyword}}
  def handle_write(%LocalFileSystem{} = object, stream, _options) do
    cond do
      is_dir?(object) ->
        {:error,
         {Lynx.Exceptions.ObjectNotWriteable,
          [object: object, details: "cannot write to a directory"]}}

      exists?(object) ->
        write_from_stream(stream, object)

      true ->
        with :ok <- File.mkdir_p(dir_path(object)) do
          write_from_stream(stream, object)
        else
          {:error, :eexist} ->
            {:error,
             {Lynx.Exceptions.MalformedURI,
              [
                object: object,
                details: """
                the subpath might contain a data file rather than a directory
                example: /a.txt/b.txt
                """
              ]}}

          {:error, reason} ->
            {:error,
             {File.Error,
              reason: reason,
              action: "make directory (with -p)",
              path: IO.chardata_to_string(path(object))}}
        end
    end
  end

  @impl true
  def handle_delete(%LocalFileSystem{} = object, _options) do
    cond do
      is_dir?(object) ->
        case object |> path() |> File.rm_rf() do
          {:ok, _} ->
            :ok

          {:error, :enoent, _} ->
            :ok

          {:error, :eacces, _} ->
            {:error,
             {Lynx.Exceptions.InsufficientPermissions,
              [object: object, details: "missing permission for the file or one of its parents"]}}

          {:error, reason, _} ->
            {:error, File.Error,
             reason: reason, action: "remove file", path: IO.chardata_to_string(path(object))}
        end

      !exists?(object) ->
        :ok

      true ->
        case object |> path() |> File.rm() do
          :ok ->
            :ok

          {:error, :enoent} ->
            :ok

          {:error, :eacces} ->
            {:error,
             {Lynx.Exceptions.InsufficientPermissions,
              [object: object, details: "missing permission for the file or one of its parents"]}}

          {:error, reason} ->
            {:error, File.Error,
             reason: reason, action: "remove file", path: IO.chardata_to_string(path(object))}
        end
    end
  end

  defp write_from_stream(stream, object) do
    stream
    |> Stream.into(stream!(object, modes: [:write, :utf8]))
    |> Stream.run()
  end

  defp stream!(object, options) do
    modes = Keyword.get(options, :modes, [])
    line_or_bytes = Keyword.get(options, :stream_mode, :bytes)

    File.stream!(path(object), modes, line_or_bytes)
  end

  defp path(%{uri: %{path: path}}), do: path
  defp dir_path(object), do: object |> path() |> Path.dirname()

  defp exists?(%{exists?: exists}), do: exists

  defp is_dir?(%{is_dir?: is_dir}), do: is_dir
end

defimpl String.Chars, for: Lynx.Adapters.LocalFileSystem do
  def to_string(%{uri: uri}), do: URI.to_string(uri)
end
