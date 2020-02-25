defmodule VFS.Adapter.NotFoundError do
  defexception [:scheme, :uri]

  @impl true
  def message(%{scheme: scheme, uri: uri}) do
    "could not find an adapter implemntation for scheme: #{scheme} in #{uri}"
  end
end
