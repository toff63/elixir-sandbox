defmodule Pool.Greeting do
  use GenServer
  @timeout 60000

  def start_link(_default) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def greet() do
    :poolboy.transaction(
      :greeting_worker,
      fn pid -> GenServer.call(pid, {:greet}) end,
      @timeout
    )
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
