defmodule VFS do
  @moduledoc """
  Documentation for `VFS`.
  """

  @type stream :: Enumerable.t() | File.Stream.t() | IO.Stream.t()
  @type scheme :: binary | atom
  @type uri :: String.t() | URI.t()

  defmacro adapter(module) do
    quote do: use(unquote(module))
  end

  @spec get(uri, [VFS.Adapter.t()]) ::
          {:ok, VFS.stream()} | {:error, {module, keyword}}
  def get(uri, adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters),
         {:ok, result} <- VFS.Adapter.get(adapter, uri) do
      {:ok, result}
    end
  end

  @spec get!(uri, [VFS.Adapter.t()]) :: VFS.stream()
  def get!(uri, adapters) do
    case get(uri, adapters) do
      {:ok, stream} -> stream
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec put(uri, uri, [VFS.Adapter.t()]) ::
          {:ok, uri}
          | {:error, {module, keyword}}
  def put(from_uri, to_uri, adapters) do
    with {:ok, stream} <- get(from_uri, adapters),
         {:ok, adapter} <- fetch_adapter(to_uri, adapters) do
      VFS.Adapter.put(adapter, stream, to_uri)
    end
  end

  @spec put!(uri, uri, [VFS.Adapter.t()]) :: uri
  def put!(from_uri, to_uri, adapters) do
    case put(from_uri, to_uri, adapters) do
      {:ok, to_uri} -> to_uri
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec fetch_adapter(uri, [VFS.Adapter.t()]) ::
          {:ok, module} | {:error, {module, keyword}}
  def fetch_adapter(uri, adapters) do
    scheme = URI.parse(uri).scheme

    case adapter_for_scheme(scheme, adapters) do
      nil -> {:error, {VFS.Adapter.NotFoundError, scheme: scheme, uri: uri}}
      adapter -> {:ok, adapter.module}
    end
  end

  defp adapter_for_scheme(scheme, adapters) do
    adapters
    |> Enum.find(nil, fn adapter -> adapter.scheme == scheme end)
  end

  defmacro __using__(_env) do
    quote do
      import VFS, only: [adapter: 1]

      def fetch_adapter(uri), do: VFS.fetch_adapter(uri, adapters())
      def get(uri), do: VFS.get(uri, adapters())
      def put(from_uri, to_uri), do: VFS.put(from_uri, to_uri, adapters())
    end
  end
end
