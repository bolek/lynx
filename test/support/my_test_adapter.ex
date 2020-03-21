defmodule MyTestAdapter do
  use Lynx.Adapter, scheme: "test"

  defstruct [:uri]

  @type t :: %MyTestAdapter{uri: URI.t()}

  @spec new(binary | URI.t()) :: {:ok, MyTestAdapter.t()} | {:error, Lynx.exception()}
  def new("bad"), do: {:error, {Lynx.Exceptions.MalformedURI, [uri: "bad"]}}

  def new(uri) do
    {:ok, %__MODULE__{uri: URI.parse(uri)}}
  end

  def handle_read(_, _options \\ []), do: {:ok, []}
  def handle_write(_, _, _options \\ []), do: :ok
  def handle_delete(_, _options), do: :ok
end

defimpl String.Chars, for: MyTestAdapter do
  def to_string(%{uri: uri}), do: URI.to_string(uri)
end
