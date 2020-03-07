defmodule Lynx.Adapters.LocalFileSystem do
  use Lynx.Adapter, :file

  defmodule Extra do
    defstruct [:is_dir?, :exists?]

    @type t :: %__MODULE__{is_dir?: boolean, exists?: boolean}

    @spec new(URI.t()) :: t
    def new(%URI{path: path}) do
      %__MODULE__{
        is_dir?: File.dir?(path),
        exists?: File.exists?(path)
      }
    end
  end

  @impl true
  @spec init_object(Lynx.Object.t()) :: {:ok, Lynx.Object.t()}
  def init_object(%Lynx.Object{uri: uri} = object) do
    {:ok, Lynx.Object.put_extra(object, Extra.new(uri))}
  end

  @impl true
  @spec read(Lynx.Object.t(Extra.t()), keyword) ::
          {:ok, File.Stream.t()}
          | {:error,
             {Lynx.Exceptions.ObjectNotFound, keyword}
             | {Lynx.Exceptions.ObjectNotReadable, keyword}}
  def read(%Lynx.Object{} = object, options \\ []) do
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
  @spec write(Lynx.Object.t(Extra.t()), Lynx.stream(), keyword) ::
          :ok
          | {:error,
             {File.Error, keyword}
             | {Lynx.Exceptions.MalformedURI, keyword}
             | {Lynx.Exceptions.ObjectNotWriteable, keyword}}
  def write(%Lynx.Object{} = object, stream, _options \\ []) do
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
  def delete(%Lynx.Object{} = object, _options \\ []) do
    cond do
      is_dir?(object) ->
        with {:ok, _} <- object |> path() |> File.rm_rf() do
          :ok
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
    line_or_bytes = Keyword.get(options, :stream_mode, :line)

    File.stream!(path(object), modes, line_or_bytes)
  end

  defp path(%{uri: %{path: path}}), do: path
  defp dir_path(object), do: object |> path() |> Path.dirname()

  defp exists?(%{extra: %{exists?: exists}}), do: exists

  defp is_dir?(%{extra: %{is_dir?: is_dir}}), do: is_dir
end
