defmodule VFS.Adapter do
  defstruct [:scheme, :module]

  @type t :: %VFS.Adapter{scheme: String.t(), module: module}

  @callback get(VFS.uri()) :: {:ok, VFS.stream()} | {:error, any}
  @callback put(VFS.uri(), VFS.uri()) :: {:ok, VFS.uri()} | {:error, any}

  defmacro __using__(scheme) do
    module = __CALLER__.module

    quote location: :keep do
      @scheme unquote(scheme)

      @behaviour VFS.Adapter

      def scheme(), do: @scheme

      defmacro __using__(_) do
        quote location: :keep, bind_quoted: [module: unquote(module), scheme: unquote(scheme)] do
          use AdapterRegistry, VFS.Adapter.new(scheme, module)
        end
      end
    end
  end

  @spec new(atom | String.t(), module) :: VFS.Adapter.t()
  def new(scheme, module) do
    %VFS.Adapter{scheme: "#{scheme}", module: module}
  end
end
