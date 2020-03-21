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

  defdelegate new(uri, adapters), to: Lynx.Adapter
  defdelegate new!(uri, adapters), to: Lynx.Adapter

  defdelegate delete(object, options), to: Lynx.Adapter
  defdelegate delete(uri, options, adapters), to: Lynx.Adapter
  defdelegate delete!(uri, options, adapters), to: Lynx.Adapter

  defdelegate read(object, options), to: Lynx.Adapter
  defdelegate read(uri, options, adapters), to: Lynx.Adapter
  defdelegate read!(uri, options, adapters), to: Lynx.Adapter

  defdelegate write(object, stream, options), to: Lynx.Adapter
  defdelegate write(uri, stream, options, adapters), to: Lynx.Adapter
  defdelegate write!(uri, stream, options, adapters), to: Lynx.Adapter

  # @spec write_to(stream, uri, keyword, [Lynx.Adapter.t()] | Lynx.Adapter.t()) ::
  #         :ok | {:error, exception}
  # def write_to(stream, uri, options, adapters) do
  #   write(uri, stream, options, adapters)
  # end

  # @spec write_to!(stream, uri, keyword, [Lynx.Adapter.t()] | Lynx.Adapter.t()) :: :ok
  # def write_to!(stream, uri, options, adapters) do
  #   write!(uri, stream, options, adapters)
  # end

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
