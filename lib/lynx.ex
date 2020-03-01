defmodule Lynx do
  @moduledoc """
  Documentation for `Lynx`.
  """

  @type stream :: Enumerable.t() | File.Stream.t() | IO.Stream.t()
  @type scheme :: binary | atom
  @type uri :: String.t() | URI.t()

  defmacro adapter(module) do
    quote do: use(unquote(module))
  end

  @spec read(uri, keyword, [Lynx.Adapter.t()]) ::
          {:ok, Lynx.stream()} | {:error, {module, keyword}}
  def read(uri, options, adapter) when is_binary(uri) do
    read(URI.parse(uri), options, adapter)
  end

  def read(uri, options, adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters),
         {:ok, result} <- Lynx.Adapter.read(adapter, uri, options) do
      {:ok, result}
    end
  end

  @spec read!(uri, keyword, [Lynx.Adapter.t()]) :: Lynx.stream()
  def read!(uri, options, adapters) when is_binary(uri) do
    read!(URI.parse(uri), options, adapters)
  end

  def read!(uri, options, adapters) do
    case read(uri, options, adapters) do
      {:ok, stream} -> stream
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec write(uri, stream, keyword, [Lynx.Adapter.t()]) :: :ok | {:error, {module, keyword}}
  def write(uri, stream, options, adapters) when is_binary(uri) do
    write(URI.parse(uri), stream, options, adapters)
  end

  def write(uri, stream, options, adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters) do
      Lynx.Adapter.write(adapter, uri, stream, options)
    end
  end

  @spec write!(uri, stream, keyword, [Lynx.Adapter.t()]) :: :ok
  def write!(uri, stream, options, adapters) when is_binary(uri) do
    write!(URI.parse(uri), stream, options, adapters)
  end

  def write!(uri, stream, options, adapters) do
    case write(uri, stream, options, adapters) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec write_to(stream, uri, keyword, [Lynx.Adapter.t()]) :: :ok | {:error, {module, keyword}}
  def write_to(stream, uri, options, adapters) do
    write(uri, stream, options, adapters)
  end

  @spec write_to!(stream, uri, keyword, [Lynx.Adapter.t()]) :: :ok
  def write_to!(stream, uri, options, adapters) do
    write!(uri, stream, options, adapters)
  end

  def delete(uri, options, adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters) do
      Lynx.Adapter.delete(adapter, uri, options)
    end
  end

  def delete!(uri, options, adapters) do
    case delete(uri, options, adapters) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec fetch_adapter(URI.t(), [Lynx.Adapter.t()]) ::
          {:ok, module} | {:error, {module, keyword}}
  def fetch_adapter(%URI{scheme: scheme} = uri, adapters) do
    case adapter_for_scheme(scheme, adapters) do
      nil -> {:error, {Lynx.Adapter.NotFoundError, uri: uri}}
      adapter -> {:ok, adapter.module}
    end
  end

  defp adapter_for_scheme(scheme, adapters) do
    adapters
    |> Enum.find(nil, fn adapter -> adapter.scheme == scheme end)
  end

  defmacro __using__(_env) do
    quote do
      import Lynx, only: [adapter: 1]

      def fetch_adapter(uri), do: Lynx.fetch_adapter(uri, adapters())
      def read(uri, options \\ []), do: Lynx.read(uri, options, adapters())
      def write(uri, stream, options \\ []), do: Lynx.write(uri, stream, options, adapters())
      def delete(uri, options \\ []), do: Lynx.delete(uri, options, adapters())
    end
  end
end
