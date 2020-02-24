defmodule VFS do
  @moduledoc """
  Documentation for `VFS`.
  """

  @type stream :: Enumerable.t() | File.Stream.t() | IO.Stream.t()
  @type scheme :: binary | atom
  @type uri :: String.t() | URI.t() | {scheme, any}


  @spec get(uri, [VFS.Adapter.t()]) :: {:ok, VFS.stream()} | {:error, any}
  def get(uri, adapters) do
    uri
    |> fetch_adapter!(adapters)
    |> apply(:get, [uri])
  end

  @spec put(uri, uri, [VFS.Adapter.t()]) :: {:ok, uri} | {:error, any}
  def put(from, to, adapters) do
    with {:ok, stream} <- get(from, adapters) do
      apply(fetch_adapter!(to, adapters), :put, [stream, to])
    end
  end

  @spec fetch_adapter!(uri, [VFS.Adapter.t()]) :: module
  def fetch_adapter!({scheme, _}, adapters) do
    fetch_adapter_for_scheme!(scheme, adapters)
  end

  def fetch_adapter!(uri, adapters) do
    scheme = URI.parse(uri).scheme
    fetch_adapter_for_scheme!(scheme, adapters)
  end

  defp fetch_adapter_for_scheme!(scheme, adapters) do
    case adapter_for_scheme(scheme, adapters) do
      nil -> raise "Adapter for scheme \"#{scheme}\" was not found."
      adapter -> adapter.module
    end
  end

  defp adapter_for_scheme(scheme, adapters) do
    adapters
    |> Enum.find(nil, fn adapter -> adapter.scheme == scheme end)
  end
  end
end
