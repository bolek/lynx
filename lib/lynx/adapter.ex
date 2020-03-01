defmodule Lynx.Adapter do
  alias __MODULE__

  @callback read(Lynx.uri(), keyword) :: {:ok, Lynx.stream()} | {:error, {module, keyword}}
  @callback write(Lynx.uri(), Lynx.stream(), keyword) :: :ok | {:error, {module, keyword}}
  @callback delete(Lynx.uri(), keyword) :: :ok | {:error, {module, keyword}}

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
    end
  end

  @spec delete(module, Lynx.uri(), keyword) :: :ok | {:error, {module, keyword}}
  def delete(adapter, uri, options \\ []), do: adapter.delete(uri, options)

  @spec read(module, Lynx.uri(), keyword) :: {:ok, Lynx.stream()}
  def read(adapter, uri, options \\ []), do: adapter.read(uri, options)

  @spec write(module, Lynx.uri(), Lynx.stream(), keyword) :: :ok | {:error, {module, keyword}}
  def write(adapter, uri, stream, options \\ []), do: adapter.write(uri, stream, options)

  defdelegate build_entry(scheme, module), to: Adapter.Registry.Entry, as: :new
end
