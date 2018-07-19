defmodule DynamicTasks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Task.Supervisor, name: DynamicTasks.TaskSupervisor},
      %{id: NoPool.Greeting, name: DynamicTasks.Greeting,  start: {DynamicTasks.Greeting, :start_link, [[]]}},
      Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: DynamicTasks.Api, options: [port: 4001])
      # Starts a worker by calling: DynamicTasks.Worker.start_link(arg)
      # {DynamicTasks.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DynamicTasks.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
