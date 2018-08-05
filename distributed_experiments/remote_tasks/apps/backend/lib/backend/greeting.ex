defmodule Backend.Greeting do
  use GenServer

  @frontend_node Application.get_env(:backend, :frontend_node)

  @spec start_link(any()) :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  def start_link(_default) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    connect_to_frontend(Node.self())
    state = refresh_backend_nodes(%{request: 0, backend_nodes: []})
    schedule_backend_refresh()
    {:ok, state}
  end

  def refresh_backend_nodes(state) do
    backend_nodes = Enum.filter(Node.list(), fn node -> node != @frontend_node end)
    %{state | backend_nodes: backend_nodes}
  end

  def connect_to_frontend(@frontend_node) do
    # No need to connect to ourself
  end

  def connect_to_frontend(_node) do
    Node.connect(@frontend_node)
  end

  @impl true
  def handle_call({:greet}, _from, %{backend_nodes: []} = state) do
    {:reply, {:ko, :no_backend_available}, state}
  end

  @impl true
  def handle_call({:greet}, from, %{request: request, backend_nodes: _nodes} = state) do
    state = %{state | request: request+1 }
    node = route(state)
    Task.Supervisor.start_child({Backend.TaskSupervisor, node}, fn ->
      local_from = from
      IO.puts("I am processing the request")
      Process.sleep(500)
      GenServer.reply(local_from, {:ok, "Hello world"})
    end)

    {:noreply, state}
  end

  def route(%{request: request, backend_nodes: nodes}) do
    node_id = rem(request, Enum.count(nodes))
    Enum.fetch!(nodes, node_id)
  end

  @impl true
  def handle_info(:refresh_backend, state) do
    state = refresh_backend_nodes(state)
    schedule_backend_refresh()
    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh_frontend, state) do
    connect_to_frontend(Node.self())
    {:noreply, state}
  end

  def schedule_backend_refresh() do
    Process.send_after(self(), :refresh_backend, 5000)
    Process.send_after(self(), :refresh_frontend, 5000)
  end
end
