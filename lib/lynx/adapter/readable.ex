defprotocol Lynx.Adapter.Readable do
  @spec from(t, Keyword.t()) :: {:ok, Enumerable.t()} | {:error, Lynx.exception()}
  def from(object, options \\ [])
end
