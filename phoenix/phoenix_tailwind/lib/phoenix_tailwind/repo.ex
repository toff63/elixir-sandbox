defmodule PhoenixTailwind.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_tailwind,
    adapter: Ecto.Adapters.Postgres
end
