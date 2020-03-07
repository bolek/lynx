defmodule Lynx.Exceptions.InsufficientPermissions do
  defexception [:object, :details]

  def exception(object: object, details: details) do
    %__MODULE__{object: object, details: details}
  end

  def exception(object: object) do
    %__MODULE__{object: object}
  end

  def message(%{object: %{uri: uri}, details: nil}) do
    "insufficient permissions: \"#{uri}\""
  end

  def message(%{object: %{uri: uri}, details: details}) do
    """
    insufficient permissions: \"#{uri}\"
    #{details}
    """
  end
end
