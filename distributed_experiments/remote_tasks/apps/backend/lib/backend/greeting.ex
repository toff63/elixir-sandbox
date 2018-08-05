defmodule Backend.Greeting do
  use GenServer

  @frontend_node Application.get_env(:backend, :frontend_node)

  @spec start_link(any()) :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  def start_link(_default) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    if Node.self() != @frontend_node, do: Node.connect(@frontend_node)
    backend_nodes = Enum.filter(Node.list(), fn node -> node != @frontend_node end)
    state = %{request: 0, backend_nodes: backend_nodes}
    schedule_backend_refresh()
    {:ok, state}
  end

  @impl true
  def handle_call({:greet}, _from, %{backend_nodes: []} = state) do
    {:reply, {:ko, :no_backend_available}, state}
  end

  @impl true
  def handle_call({:greet}, from, %{request: request, backend_nodes: nodes}) do
    request = request + 1
    node_id = rem(request, Enum.count(nodes))
    node = Enum.fetch!(nodes, node_id)

    Task.Supervisor.start_child({Backend.TaskSupervisor, node}, fn ->
      local_from = from
      Process.sleep(500)
      IO.puts("I am node #{node()}")
      GenServer.reply(local_from, {:ok, "Hello world"})
    end)

    {:noreply, %{request: request, backend_nodes: nodes}}
  end

  @impl true
  def handle_info(:refresh, state) do
    backend_nodes = Enum.filter(Node.list(), fn node -> node != @frontend_node end)
    schedule_backend_refresh()
    {:noreply, %{state | backend_nodes: backend_nodes}}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end

  def schedule_backend_refresh() do
    Process.send_after(self(), :refresh, 5000)
  end
end
