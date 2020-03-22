defmodule Lynx do
  @moduledoc """
  Documentation for `Lynx`.
  """

  @type scheme :: binary | atom
  @type uri :: String.t() | URI.t()

  @type exception_attributes :: keyword
  @type exception :: {module, exception_attributes}

  @callback new(Lynx.uri()) :: {:ok, Lynx.Object.t()} | {:error, exception}
  @callback new!(Lynx.uri()) :: Lynx.Object.t()

  defmacro adapter(module) do
    quote do: use(unquote(module))
  end

  defdelegate new(uri, adapters), to: Lynx.Adapter
  defdelegate new!(uri, adapters), to: Lynx.Adapter

  defdelegate delete(object, options), to: Lynx.Adapter
  defdelegate delete!(object, options), to: Lynx.Adapter

  defdelegate read(object, options), to: Lynx.Adapter
  defdelegate read!(object, options), to: Lynx.Adapter

  defdelegate write(object, enum, options), to: Lynx.Adapter
  defdelegate write!(object, enum, options), to: Lynx.Adapter

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
      import Lynx

      @behaviour Lynx

      def new(uri), do: Lynx.new(uri, adapters())
      def new!(uri), do: Lynx.new!(uri, adapters())
    end
  end
end
