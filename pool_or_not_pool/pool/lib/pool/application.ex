defmodule Pool.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application


  defp poolboy_config do
    [
      {:name, {:local, :greeting_worker}},
      {:worker_module, Pool.Greeting},
      {:size, 100},
      {:max_overflow, 2}
    ]
  end

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Pool.Worker.start_link(arg)
      # {Pool.Worker, arg},
      :poolboy.child_spec(:worker, poolboy_config()),
      Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: Pool.Api, options: [port: 4001])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pool.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
