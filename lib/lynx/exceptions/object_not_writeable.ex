defmodule Lynx.Exceptions.ObjectNotWriteable do
  alias __MODULE__
  defexception [:object, :details]

  def exception(object: object, details: details) do
    %ObjectNotWriteable{object: object, details: details}
  end

  def execption(object: object) do
    %ObjectNotWriteable{object: object}
  end

  def message(%{object: %{uri: uri}, details: nil}) do
    "cannot write to: \"#{uri}\""
  end

  def message(%{object: %{uri: uri}, details: details}) do
    """
    cannot write to: \"#{uri}\"
    #{details}
    """
  end
end
