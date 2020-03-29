defmodule MyTestAdapter do
  use Lynx.Adapter, scheme: "test"

  defstruct [:uri]

  @type t :: %MyTestAdapter{uri: URI.t()}

  @spec new(binary | URI.t()) :: {:ok, MyTestAdapter.t()} | {:error, Lynx.exception()}
  def new("bad"), do: {:error, {Lynx.Exceptions.MalformedURI, [uri: "bad"]}}

  def new(uri) do
    {:ok, %__MODULE__{uri: URI.parse(uri)}}
  end

  def handle_delete(_, _options), do: :ok

  defimpl Lynx.Adapter.Readable do
    def from(object, error: "error"),
      do: {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}

    def from(_, _), do: {:ok, []}
  end

  defimpl Lynx.Adapter.Writable do
    def to(object, error: "error"),
      do: {:error, {Lynx.Exceptions.ObjectNotFound, [object: object]}}

    def to(_, _), do: {:ok, []}
  end
end

defimpl String.Chars, for: MyTestAdapter do
  def to_string(%{uri: uri}), do: URI.to_string(uri)
end
