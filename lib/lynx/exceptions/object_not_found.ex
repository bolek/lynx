defmodule Lynx.Exceptions.ObjectNotFound do
  alias __MODULE__
  defexception [:object]

  def exception(object: object) do
    %ObjectNotFound{object: object}
  end

  def message(%{object: %{uri: uri}}) do
    "not found: \"#{uri}\""
  end
end
