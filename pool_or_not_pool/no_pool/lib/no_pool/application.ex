defmodule NoPool.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: NoPool.Worker.start_link(arg)
      # {NoPool.Worker, arg},
      %{id: NoPool.Greeting, name: NoPool.Greeting,  start: {NoPool.Greeting, :start_link, [[]]}},
      Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: NoPool.Api, options: [port: 4001])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NoPool.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
