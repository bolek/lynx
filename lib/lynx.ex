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

  defdelegate from(object, options), to: Lynx.Adapter
  defdelegate from!(object, options), to: Lynx.Adapter

  defdelegate to(from, to, options), to: Lynx.Adapter
  defdelegate to!(from, to, options), to: Lynx.Adapter

  def run({:ok, stream}), do: run(stream)
  def run({:error, _} = error), do: error
  def run(stream), do: Stream.run(stream)

  defmacro __using__(_env) do
    quote do
      import Lynx

      @behaviour Lynx

      def new(uri), do: Lynx.new(uri, adapters())
      def new!(uri), do: Lynx.new!(uri, adapters())
    end
  end
end
