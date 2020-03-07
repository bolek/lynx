defmodule Lynx.Exceptions.ObjectNotWriteable do
  alias __MODULE__
  defexception [:uri, :details]

  def exception(uri: uri, details: details) do
    %ObjectNotWriteable{uri: uri, details: details}
  end

  def execption(uri: uri) do
    %ObjectNotWriteable{uri: uri}
  end

  def message(%{uri: uri, details: nil}) do
    "cannot write to: \"#{uri}\""
  end

  def message(%{uri: uri, details: details}) do
    """
    cannot write to: \"#{uri}\"
    #{details}
    """
  end
end
