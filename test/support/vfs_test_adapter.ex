defmodule VFSTestAdapter do
  use VFS.Adapter, :test

  @spec get({VFS.scheme(), list}) :: {:ok, VFS.stream()}
  def get({"test", data}) do
    {:ok,
     Stream.resource(
       fn -> data end,
       fn
         [] -> {:halt, []}
         [h | t] -> {[h], t}
       end,
       fn _ -> :ok end
     )}
  end

  @spec put(VFS.stream(), VFS.uri()) :: {:ok, VFS.uri()} | {:error, any}
  def put(stream, {"test", []}) do
    {:ok, {"test", Enum.to_list(stream)}}
  end
end
