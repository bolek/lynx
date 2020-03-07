defmodule Lynx.Exceptions.ObjectNotReadable do
  alias __MODULE__
  defexception [:uri, :details]

  def exception(uri: uri, details: details) do
    %ObjectNotReadable{uri: uri, details: details}
  end

  def exception(uri: uri) do
    %ObjectNotReadable{uri: uri}
  end

  def message(%{uri: uri, details: nil}) do
    "cannot read from: \"#{uri}\""
  end

  def message(%{uri: uri, details: details}) do
    """
    cannot read from: \"#{uri}\"
    #{details}
    """
  end
end
