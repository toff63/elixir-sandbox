# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phoenix_tailwind,
  ecto_repos: [PhoenixTailwind.Repo]

# Configures the endpoint
config :phoenix_tailwind, PhoenixTailwindWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AXyYPhCsX00FuYaWu3v8ghaYmkw4Z/B1UoOm+t4Hl+8URK+vgby8s80HNmEKc3HE",
  render_errors: [view: PhoenixTailwindWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PhoenixTailwind.PubSub,
  live_view: [signing_salt: "KS1O0Bd0"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
