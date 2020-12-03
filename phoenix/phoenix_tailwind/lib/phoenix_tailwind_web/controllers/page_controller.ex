defmodule PhoenixTailwindWeb.PageController do
  use PhoenixTailwindWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
