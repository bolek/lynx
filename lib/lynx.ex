defmodule Lynx do
  @moduledoc """
  Documentation for `Lynx`.
  """

  @type stream :: Enumerable.t() | File.Stream.t() | IO.Stream.t()
  @type scheme :: binary | atom
  @type uri :: String.t() | URI.t()

  @type exception_attributes :: keyword
  @type exception :: {module, exception_attributes}

  defmacro adapter(module) do
    quote do: use(unquote(module))
  end

  @spec to_object(uri, [Lynx.Adapter.t()] | Lynx.Adapter.t()) ::
          {:ok, Lynx.Object.t()} | {:error, any}
  def to_object(uri, adapters) when is_binary(uri) do
    to_object(URI.parse(uri), adapters)
  end

  def to_object(uri, adapters) when is_list(adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters) do
      to_object(uri, adapter)
    end
  end

  def to_object(uri, adapter) do
    Lynx.Object.new(uri, adapter)
  end

  @spec to_object!(uri, [Lynx.Adapter.t()] | Lynx.Adapter.t()) :: Lynx.Object.t()
  def to_object!(uri, adapters) do
    case to_object(uri, adapters) do
      {:ok, object} -> object
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec read(Lynx.Object.t(), keyword) :: {:ok, Lynx.Stream.t()} | {:error, exception}
  def read(%Lynx.Object{} = object, options) do
    Lynx.Adapter.read(object, options)
  end

  @spec read(uri, keyword, [Lynx.Adapter.t()]) ::
          {:ok, Lynx.stream()} | {:error, exception}
  def read(uri, options, adapters)

  def read(uri, options, adapters) do
    with {:ok, object} <- to_object(uri, adapters) do
      read(object, options)
    end
  end

  @spec read!(uri, keyword, [Lynx.Adapter.t()]) :: Lynx.Stream.t()
  def read!(uri, options, adapters) do
    case read(uri, options, adapters) do
      {:ok, stream} -> stream
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec write(Lynx.Object.t(), stream, keyword) :: :ok | {:error, exception}
  def write(%Lynx.Object{} = object, stream, options) do
    Lynx.Adapter.write(object, stream, options)
  end

  @spec write(uri, stream, keyword, [Lynx.Adapter.t()]) :: :ok | {:error, exception}
  def write(uri, stream, options, adapters)

  def write(%Lynx.Object{} = object, stream, options, _adapters) do
    write(object, stream, options)
  end

  def write(uri, stream, options, adapters) do
    with {:ok, object} <- to_object(uri, adapters) do
      write(object, stream, options)
    end
  end

  @spec write!(uri, stream, keyword, [Lynx.Adapter.t()]) :: :ok | {:error, exception}
  def write!(uri, stream, options, adapters) do
    case write(uri, stream, options, adapters) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec write_to(stream, uri, keyword, [Lynx.Adapter.t()]) :: :ok | {:error, exception}
  def write_to(stream, uri, options, adapters) do
    write(uri, stream, options, adapters)
  end

  @spec write_to!(stream, uri, keyword, [Lynx.Adapter.t()]) :: :ok
  def write_to!(stream, uri, options, adapters) do
    write!(uri, stream, options, adapters)
  end

  @spec delete(Lynx.Object.t(), keyword) :: :ok | {:error, exception}
  def delete(%Lynx.Object{} = object, options) do
    Lynx.Adapter.delete(object, options)
  end

  @spec delete(uri, keyword, [Lynx.Adapter.t()]) :: :ok | {:error, exception}
  def delete(uri, options, adapters)

  def delete(%Lynx.Object{} = object, options, _adapters) do
    delete(object, options)
  end

  def delete(uri, options, adapters) do
    with {:ok, object} <- to_object(uri, adapters) do
      delete(object, options)
    end
  end

  @spec delete!(uri, keyword, [Lynx.Adapter.t()]) :: :ok
  def delete!(uri, options, adapters) do
    case delete(uri, options, adapters) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec fetch_adapter(URI.t(), [Lynx.Adapter.t()]) ::
          {:ok, module} | {:error, exception}
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
