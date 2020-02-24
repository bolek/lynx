# Thank you - https://gist.github.com/christhekeele/fc4e058ee7d117016b9b041b83c6546a

defmodule AdapterRegistry do
  defmodule Registry do
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
      @before_compile Registry
      Module.register_attribute(__MODULE__, :adapters, accumulate: true)
      Module.put_attribute(__MODULE__, :adapters, unquote(adapter))
    end
  end
end
