defmodule DynamicTasks.Greeting do
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
  def handle_call({:greet}, from, state) do
    Task.Supervisor.start_child(DynamicTasks.TaskSupervisor, fn ->
      local_from = from
      Process.sleep(500)
      GenServer.reply(local_from, {:ok, "Hello world"})
    end)
    {:noreply, state}
  end

end
