defmodule NoPool.Api do
  use Plug.Router

  plug :match
  plug :dispatch


  get "/hello" do
    {:ok, greet} = NoPool.Greeting.greet()
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, greet)
  end
end
