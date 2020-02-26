defmodule VFS.Adapter do
  alias __MODULE__

  @callback read(VFS.uri(), keyword) :: {:ok, VFS.stream()} | {:error, {module, keyword}}
  @callback write(VFS.uri(), VFS.stream(), keyword) :: :ok | {:error, {module, keyword}}

  defmacro __using__(scheme) do
    module = __CALLER__.module

    quote location: :keep do
      @scheme unquote(scheme)

      @behaviour VFS.Adapter

      def scheme(), do: @scheme

      defmacro __using__(_) do
        quote location: :keep, bind_quoted: [module: unquote(module), scheme: unquote(scheme)] do
          use Adapter.Registry, Adapter.build_entry(scheme, module)
        end
      end
    end
  end

  @spec read(module, VFS.uri(), keyword) :: {:ok, VFS.stream()}
  def read(adapter, uri, options \\ []), do: adapter.read(uri, options)

  @spec write(module, VFS.uri(), VFS.stream(), keyword) :: :ok | {:error, {module, keyword}}
  def write(adapter, uri, stream, options \\ []), do: adapter.write(uri, stream, options)

  defdelegate build_entry(scheme, module), to: Adapter.Registry.Entry, as: :new
end
