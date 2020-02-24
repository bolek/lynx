defmodule VFS do
  @moduledoc """
  Documentation for `VFS`.
  """

  @type stream :: Enumerable.t() | File.Stream.t() | IO.Stream.t()
  @type scheme :: binary | atom
  @type uri :: String.t() | URI.t() | {scheme, any}

  ## Examples

      iex> VFS.hello()
      :world

  """
  def hello do
    :world
  end
end
