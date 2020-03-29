defmodule Lynx.Exceptions.ObjectExists do
  alias __MODULE__
  defexception [:object]

  def exception(object: object) do
    %ObjectExists{object: object}
  end

  def message(%{object: %{uri: uri}}) do
    "already exists: \"#{uri}\""
  end
end
