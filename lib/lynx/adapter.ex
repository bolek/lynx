defmodule Lynx.AdapterDefaults do
  defmacro __before_compile__(%{module: module}) do
    quote do
      def new!(uri) do
        Lynx.Adapter.new!(uri, unquote(module))
      end

      def delete(object_or_uri, options \\ [])
      def delete(object, options) when is_struct(object), do: handle_delete(object, options)

      # def delete(uri, options), do: Lynx.delete(uri, options, unquote(module))
    end
  end
end

defmodule Lynx.Adapter do
  alias __MODULE__

  @type t :: module

  @callback new(Lynx.uri()) :: {:ok, Lynx.Object.t()} | {:error, Lynx.exception()}

  # @callback delete(Lynx.uri() | Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}
  @callback handle_delete(Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}

  defmacro __using__(opts) do
    module = __CALLER__.module
    scheme = Keyword.fetch!(opts, :scheme)

    quote location: :keep do
      @before_compile Lynx.AdapterDefaults

      @behaviour Lynx.Adapter

      @scheme unquote(scheme)

      def scheme(), do: @scheme

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

  def new!(uri, adapters) do
    case new(uri, adapters) do
      {:ok, object} -> object
      {:error, {module, args}} -> raise module, args
    end
  end

  def from(object, options \\ []) do
    if Adapter.Readable.impl_for(object) do
      Adapter.Readable.from(object, options)
    else
      {:error, {Lynx.Exceptions.ObjectNotReadable, [object: object]}}
    end
  end

  def from!(object, options \\ []) do
    case from(object, options) do
      {:ok, object} -> object
      {:error, {module, args}} -> raise module, args
    end
  end

  def to(from, object, options \\ [])
  def to({:ok, from}, object, options), do: to(from, object, options)
  def to({:error, _} = error, _, _), do: error

  def to(from, object, options) do
    if Adapter.Writable.impl_for(object) do
      with {:ok, to_stream} <- Adapter.Writable.to(object, options) do
        {:ok, Stream.into(from, to_stream)}
      end
    else
      {:error, {Lynx.Exceptions.ObjectNotWritable, [object: object]}}
    end
  end

  def to!(from, object, options \\ []) do
    case to(from, object, options) do
      {:ok, object} -> object
      {:error, {module, args}} -> raise module, args
    end
  end

  def into(from, object, options), do: to(from, object, options)

  @spec delete(Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}
  def delete(object, options \\ []) when is_struct(object),
    do: object.__struct__.delete(object, options)

  @spec delete!(Lynx.Object.t(), keyword) :: :ok
  def delete!(object, options \\ []) when is_struct(object) do
    case delete(object, options) do
      :ok -> :ok
      {:error, {module, args}} -> raise module, args
    end
  end

  defdelegate build_entry(scheme, module), to: Adapter.Registry.Entry, as: :new

  @spec fetch_adapter(URI.t(), [Lynx.Object.t() | Lynx.Object.t()]) ::
          {:ok, module} | {:error, Lynx.exception()}
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
end
