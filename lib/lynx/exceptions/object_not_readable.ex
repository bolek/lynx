defmodule Lynx.Exceptions.ObjectNotReadable do
  alias __MODULE__
  defexception [:object, :details]

  def exception(object: object, details: details) do
    %ObjectNotReadable{object: object, details: details}
  end

  def exception(object: object) do
    %ObjectNotReadable{object: object}
  end

  def message(%{object: %{uri: uri}, details: nil}) do
    "cannot read from: \"#{uri}\""
  end

  def message(%{object: %{uri: uri}, details: details}) do
    """
    cannot read from: \"#{uri}\"
    #{details}
    """
  end
end
