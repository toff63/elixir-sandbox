defmodule Backend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Backend.Greeting,
        name: Backend.Greeting,
        start: {Backend.Greeting, :start_link, [[]]}
      },
      {Task.Supervisor, name: Backend.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Backend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
