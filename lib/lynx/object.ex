defprotocol Lynx.Object do
  # @spec adapter(t) :: module
  # def adapter(object)

  @spec to_string(t) :: String.t()
  def to_string(object)

  # @enforce_keys [:uri, :adapter]
  # defstruct [:uri, :adapter, extra: %{}]

  # @type t :: %__MODULE__{uri: URI.t(), adapter: module, extra: map}
  # @type t(extra) :: %__MODULE__{uri: URI.t(), adapter: module, extra: extra}

  # @spec new(binary | URI.t(), Lynx.Adapter.t()) ::
  #         {:ok, Lynx.Object.t()} | {:error, Lynx.exception()}
  # def new(uri, adapter)

  # def new(uri, adapter) when is_binary(uri) do
  #   new(URI.parse(uri), adapter)
  # end

  # def new(%URI{} = uri, adapter) do
  #   %__MODULE__{
  #     uri: uri,
  #     adapter: adapter
  #   }
  #   |> Lynx.Adapter.init_object()
  # end

  # @spec new!(binary | URI.t(), Lynx.Adapter.t()) :: Lynx.Object.t()
  # def new!(uri, adapter) do
  #   case new(uri, adapter) do
  #     {:ok, object} -> object
  #     {:error, {module, args}} -> raise module, args
  #   end
  # end

  # @spec put_extra(Lynx.Object.t(), any) :: Lynx.Object.t()
  # def put_extra(object, extra), do: %{object | extra: extra}
end
