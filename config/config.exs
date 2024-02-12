# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :backend_fight,
  ecto_repos: [BackendFight.Repo.Local],
  generators: [timestamp_type: :utc_datetime],
  test?: false

# Configures the endpoint
config :backend_fight, BackendFightWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: BackendFightWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BackendFight.PubSub,
  live_view: [signing_salt: "nZnFQXkC"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
