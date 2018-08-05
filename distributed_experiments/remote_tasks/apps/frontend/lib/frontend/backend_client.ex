defmodule Frontend.BackendClient do
  def greet() do
    GenServer.call(Backend.Greeting, {:greet})
  end
end
