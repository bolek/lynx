# Thank you - https://gist.github.com/christhekeele/fc4e058ee7d117016b9b041b83c6546a

defmodule Lynx.Adapter.Registry do
  defmodule Entry do
    @enforce_keys [:scheme, :module]
    defstruct [:scheme, :module]

    @type t :: %__MODULE__{scheme: Lynx.scheme(), module: module}

    @spec new(Lynx.scheme(), module) :: t()
    def new(scheme, module) do
      %__MODULE__{scheme: "#{scheme}", module: module}
    end
  end

  defmodule Getter do
    defmacro __before_compile__(_) do
      quote do
        def adapters() do
          @adapters
        end
      end
    end
  end

  defmacro __using__(adapter) do
    quote do
      @before_compile Getter
      Module.register_attribute(__MODULE__, :adapters, accumulate: true)
      Module.put_attribute(__MODULE__, :adapters, unquote(adapter))
    end
  end
end
