defmodule VFS.Adapter do
  alias __MODULE__

  @callback get(VFS.uri()) :: {:ok, VFS.stream()} | {:error, any}
  @callback put(VFS.stream(), VFS.uri()) :: {:ok, VFS.uri()} | {:error, any}

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

  @spec get(module, VFS.uri()) :: {:ok, VFS.stream()}
  def get(adapter, uri), do: adapter.get(uri)

  @spec put(module, VFS.stream(), VFS.uri()) :: {:ok, VFS.uri()}
  def put(adapter, stream, uri), do: adapter.put(stream, uri)

  defdelegate build_entry(scheme, module), to: Adapter.Registry.Entry, as: :new
end
