defmodule Lynx.Adapter.NotFoundError do
  defexception [:uri]

  @impl true
  def message(%{uri: uri}) do
    "could not find an adapter implementation for scheme \"#{uri.scheme}\" in \"#{uri}\""
  end
end
