defmodule Lynx.Exceptions.ObjectNotFound do
  alias __MODULE__
  defexception [:uri]

  def exception(uri) do
    %ObjectNotFound{uri: uri}
  end

  def message(%{uri: uri}) do
    "not found: \"#{uri}\""
  end
end
