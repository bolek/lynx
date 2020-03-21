defmodule Lynx.AdapterDefaults do
  defmacro __before_compile__(%{module: module}) do
    quote do
      def scheme(), do: @scheme

      def new!(uri) do
        Lynx.Adapter.new!(uri, unquote(module))
      end

      def delete(object_or_uri, options \\ [])
      def delete(object, options) when is_struct(object), do: handle_delete(object, options)
      def delete(uri, options), do: Lynx.delete(uri, options, unquote(module))

      def read(object_or_uri, options \\ [])
      def read(object, options) when is_struct(object), do: handle_read(object, options)
      def read(uri, options), do: Lynx.read(uri, options, unquote(module))

      def write(object_or_uri, stream, options \\ [])

      def write(object, stream, options) when is_struct(object),
        do: handle_write(object, stream, options)

      def write(uri, stream, options), do: Lynx.write(uri, stream, options, unquote(module))
    end
  end
end

defmodule Lynx.Adapter do
  alias __MODULE__

  @type t :: module

  @callback new(Lynx.uri()) :: {:ok, Lynx.Object.t()} | {:error, Lynx.exception()}
  # @callback read(Lynx.uri() | Lynx.Object.t(), keyword) ::
  #             {:ok, Lynx.stream()} | {:error, Lynx.exception()}
  @callback handle_read(Lynx.Object.t(), keyword) ::
              {:ok, Lynx.stream()} | {:error, Lynx.exception()}
  # @callback write(Lynx.uri() | Lynx.Object.t(), Lynx.stream(), keyword) ::
  #             :ok | {:error, Lynx.exception()}
  @callback handle_write(Lynx.Object.t(), Lynx.stream(), keyword) ::
              :ok | {:error, Lynx.exception()}
  # @callback delete(Lynx.uri() | Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}
  @callback handle_delete(Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}

  defmacro __using__(opts) do
    module = __CALLER__.module
    scheme = Keyword.fetch!(opts, :scheme)

    quote location: :keep do
      @before_compile Lynx.AdapterDefaults

      @behaviour Lynx.Adapter

      @scheme unquote(scheme)

      defmacro __using__(_) do
        quote location: :keep,
              bind_quoted: [module: unquote(module), scheme: unquote(scheme)] do
          use Adapter.Registry, Adapter.build_entry(scheme, module)
        end
      end
    end
  end

  @spec new(Lynx.uri(), [t] | t) ::
          {:ok, Lynx.Object.t()} | {:error, any}
  def new(uri, adapters) when is_binary(uri) do
    new(URI.parse(uri), adapters)
  end

  def new(uri, adapters) when is_list(adapters) do
    with {:ok, adapter} <- fetch_adapter(uri, adapters) do
      new(uri, adapter)
    end
  end

  def new(uri, adapter) do
    adapter.new(uri)
  end

  def new!(uri, module) do
    case module.new(uri) do
      {:ok, object} -> object
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec delete(Lynx.uri(), keyword, [t] | t) :: :ok | {:error, Lynx.exception()}
  def delete(uri, options, adapters)

  def delete(object, options, _adapters) when is_struct(object) do
    delete(object, options)
  end

  def delete(uri, options, adapters) do
    with {:ok, object} <- new(uri, adapters) do
      delete(object, options)
    end
  end

  @spec delete!(Lynx.uri(), keyword, [t] | t) :: :ok
  def delete!(uri, options, adapters) do
    case delete(uri, options, adapters) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec read(Lynx.uri(), keyword, [t] | t) ::
          {:ok, Lynx.stream()} | {:error, Lynx.exception()}
  def read(uri, options, adapters)

  def read(uri, options, adapters) do
    with {:ok, object} <- new(uri, adapters) do
      read(object, options)
    end
  end

  @spec read!(Lynx.uri(), keyword, [t()] | t()) :: Lynx.Stream.t()
  def read!(uri, options, adapters) do
    case read(uri, options, adapters) do
      {:ok, stream} -> stream
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec write(Lynx.uri(), Lynx.stream(), keyword, [t] | t) ::
          :ok | {:error, Lynx.exception()}
  def write(uri, stream, options, adapters)

  def write(object, stream, options, _adapters) when is_struct(object) do
    write(object, stream, options)
  end

  def write(uri, stream, options, adapters) do
    with {:ok, object} <- new(uri, adapters) do
      write(object, stream, options)
    end
  end

  @spec write!(Lynx.uri(), Lynx.stream(), keyword, [t] | t) ::
          :ok | {:error, Lynx.exception()}
  def write!(uri, stream, options, adapters) do
    case write(uri, stream, options, adapters) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  @spec delete(Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}
  def delete(object, options \\ []),
    do: object.__struct__.delete(object, options)

  @spec read(Lynx.Object.t(), keyword) ::
          {:ok, Lynx.stream()} | {:error, Lynx.exception()}
  def read(object, options \\ []),
    do: object.__struct__.read(object, options)

  @spec write(Lynx.Object.t(), Lynx.stream(), keyword) ::
          :ok | {:error, Lynx.exception()}
  def write(object, stream, options \\ []),
    do: object.__struct__.write(object, stream, options)

  defdelegate build_entry(scheme, module), to: Adapter.Registry.Entry, as: :new

  @spec fetch_adapter(URI.t(), [Lynx.Object.t() | Lynx.Object.t()]) ::
          {:ok, module} | {:error, Lynx.exception()}
  defp fetch_adapter(%URI{scheme: scheme} = uri, adapters) do
    case adapter_for_scheme(scheme, adapters) do
      nil -> {:error, {Lynx.Adapter.NotFoundError, uri: uri}}
      adapter -> {:ok, adapter.module}
    end
  end

  defp adapter_for_scheme(scheme, adapters) do
    adapters
    |> Enum.find(nil, fn adapter -> adapter.scheme == scheme end)
  end
end
