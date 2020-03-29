defmodule Lynx.Adapters.LocalFileSystem do
  alias __MODULE__
  use Lynx.Adapter, scheme: :file

  defstruct [:is_dir?, :exists?, :uri]

  @type t :: %LocalFileSystem{is_dir?: boolean, exists?: boolean, uri: URI.t()}

  @impl true
  @spec new(binary | URI.t()) :: {:ok, Lynx.Adapters.LocalFileSystem.t()}
  def new(uri) do
    parsed_uri = URI.parse(uri)

    {:ok,
     %__MODULE__{
       uri: parsed_uri,
       is_dir?: File.dir?(parsed_uri.path),
       exists?: File.exists?(parsed_uri.path)
     }}
  end

  defimpl Lynx.Adapter.Readable do
    def from(%{is_dir?: false, exists?: true} = object, options),
      do: {:ok, LocalFileSystem.stream!(object, options)}

    def from(%{is_dir?: true} = object, _),
      do:
        {:error,
         {Lynx.Exceptions.ObjectNotReadable,
          [object: object, details: "expected to read a data file, received a directory"]}}

    def from(%{exists?: false} = object, _),
      do: {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}
  end

  defimpl Lynx.Adapter.Writable do
    def to(object, options \\ []) do
      with :ok <- file_exists_check(object, options),
           :ok <- file_is_not_directory(object),
           :ok <- is_valid_path(object) do
        {:ok, LocalFileSystem.stream!(object, options)}
      end
    end

    defp file_exists_check(%{exists?: true} = object, options) do
      case Keyword.get(options, :file_exists, :override) do
        :override ->
          :ok

        :fail ->
          {:error, {Lynx.Exceptions.ObjectExists, [object: object]}}
      end
    end

    defp file_exists_check(_, _), do: :ok

    defp file_is_not_directory(%{is_dir?: true} = object),
      do:
        {:error,
         {Lynx.Exceptions.ObjectNotWriteable,
          [object: object, details: "cannot write to a directory"]}}

    defp file_is_not_directory(_), do: :ok

    defp is_valid_path(object) do
      if LocalFileSystem.path(object) |> Path.dirname() |> is_valid_subpath() do
        :ok
      else
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

    defp is_valid_subpath("/"), do: true
    defp is_valid_subpath("."), do: true

    defp is_valid_subpath(subpath) do
      if !File.exists?(subpath) || File.dir?(subpath) do
        is_valid_subpath(Path.dirname(subpath))
      else
        false
      end
    end
  end

  def stream!(object, options) do
    modes = Keyword.get(options, :modes, [])
    line_or_bytes = Keyword.get(options, :stream_mode, :bytes)

    File.stream!(path(object), modes, line_or_bytes)
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

  def path(%{uri: %{path: path}}), do: path

  defp exists?(%{exists?: exists}), do: exists

  defp is_dir?(%{is_dir?: is_dir}), do: is_dir
end

defimpl String.Chars, for: Lynx.Adapters.LocalFileSystem do
  def to_string(%{uri: uri}), do: URI.to_string(uri)
end
