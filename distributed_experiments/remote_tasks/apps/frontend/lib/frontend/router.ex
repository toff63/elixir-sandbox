defmodule Frontend.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/hello" do
    case Frontend.BackendClient.greet() do
      {:ok, greet} ->
        conn
        |> put_resp_content_type("plain/text")
        |> send_resp(200, greet)

      {:ko, :no_backend_available} ->
        conn |> send_resp(503, "")
    end
  end
end
