defmodule NoPool.Greeting do
  use GenServer

  def start_link(_default) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def greet() do
    GenServer.call(__MODULE__, {:greet})
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def handle_call({:greet}, _from, state) do
    Process.sleep(500)
    {:reply, {:ok, "Hello world"}, state}
  end

end
