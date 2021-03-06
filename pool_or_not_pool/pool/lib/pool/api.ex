defmodule Pool.Api do
  use Plug.Router

  plug :match
  plug :dispatch


  get "/hello" do
    {:ok, greet} = Pool.Greeting.greet()
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, greet)
  end
end
