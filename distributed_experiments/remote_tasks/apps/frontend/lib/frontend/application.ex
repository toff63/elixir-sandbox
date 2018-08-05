defmodule Frontend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = children(node())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Frontend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def children(:"frontend@127.0.0.1") do
    [
      Plug.Adapters.Cowboy2.child_spec(
        scheme: :http,
        plug: Frontend.Router,
        options: [port: 4001]
      )
    ]
  end

  def children(_), do: []
end
