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

  @spec read(uri, keyword, [VFS.Adapter.t()]) ::
          {:ok, VFS.stream()} | {:error, {module, keyword}}
  def read(uri, options, adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters),
         {:ok, result} <- VFS.Adapter.read(adapter, uri, options) do
      {:ok, result}
    end
  end

  @spec read!(uri, keyword, [VFS.Adapter.t()]) :: VFS.stream()
  def read!(uri, options, adapters) do
    case read(uri, options, adapters) do
      {:ok, stream} -> stream
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec write(uri, stream, keyword, [VFS.Adapter.t()]) :: :ok | {:error, {module, keyword}}
  def write(uri, stream, options, adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters) do
      VFS.Adapter.write(adapter, uri, stream, options)
    end
  end

  @spec write!(uri, stream, keyword, [VFS.Adapter.t()]) :: :ok | {:error, {module, keyword}}
  def write!(uri, stream, options, adapters) do
    case write(uri, stream, options, adapters) do
      :ok -> :ok
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
      def read(uri, options \\ []), do: VFS.read(uri, options, adapters())
      def write(uri, stream, options \\ []), do: VFS.write(uri, stream, options, adapters())
    end
  end
end
