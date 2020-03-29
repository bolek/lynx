defprotocol Lynx.Adapter.Writable do
  @spec to(t, Keyword.t()) :: {:ok, Collectable.t()} | {:error, Lynx.exception()}
  def to(object, options \\ [])
end
