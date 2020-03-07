defmodule Lynx.Adapter do
  alias __MODULE__

  @callback read(Lynx.Object.t(), keyword) :: {:ok, Lynx.stream()} | {:error, Lynx.exception()}
  @callback write(Lynx.Object.t(), Lynx.stream(), keyword) :: :ok | {:error, Lynx.exception()}
  @callback delete(Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}
  @callback init_object(Lynx.Object.t()) :: {:ok, Lynx.Object.t()} | {:error, Lynx.exception()}

  defmacro __using__(scheme) do
    module = __CALLER__.module

    quote location: :keep do
      @scheme unquote(scheme)

      @behaviour Lynx.Adapter

      def scheme(), do: @scheme

      defmacro __using__(_) do
        quote location: :keep, bind_quoted: [module: unquote(module), scheme: unquote(scheme)] do
          use Adapter.Registry, Adapter.build_entry(scheme, module)
        end
      end

      def to_object(uri), do: Lynx.to_object(uri, unquote(module))
      def to_object!(uri), do: Lynx.to_object!(uri, unquote(module))
    end
  end

  @spec delete(Lynx.Object.t(), keyword) :: :ok | {:error, Lynx.exception()}
  def delete(%Lynx.Object{adapter: adapter} = object, options \\ []),
    do: adapter.delete(object, options)

  @spec read(Lynx.Object.t(), keyword) ::
          {:ok, Lynx.stream()} | {:error, Lynx.exception()}
  def read(%Lynx.Object{adapter: adapter} = object, options \\ []),
    do: adapter.read(object, options)

  @spec write(Lynx.Object.t(), Lynx.stream(), keyword) ::
          :ok | {:error, Lynx.exception()}
  def write(%Lynx.Object{adapter: adapter} = object, stream, options \\ []),
    do: adapter.write(object, stream, options)

  @spec init_object(Lynx.Object.t()) :: {:ok, Lynx.Object.t()} | {:error, Lynx.exception()}
  def init_object(%Lynx.Object{adapter: adapter} = object),
    do: adapter.init_object(object)

  defdelegate build_entry(scheme, module), to: Adapter.Registry.Entry, as: :new
end
