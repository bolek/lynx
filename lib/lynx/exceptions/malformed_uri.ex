defmodule Lynx.Exceptions.MalformedURI do
  alias __MODULE__
  defexception [:uri, :details]

  def exception(uri: uri, details: details) do
    %MalformedURI{uri: uri, details: details}
  end

  def exception(uri: uri) do
    %MalformedURI{uri: uri}
  end

  def message(%{uri: uri, details: nil}) do
    "malformed URI: \"#{uri}\""
  end

  def message(%{uri: uri, details: details}) do
    "malformed URI, #{details}: \"#{uri}\""
  end
end
