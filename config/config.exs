# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :baule_bio, :scopes,
  utilisateur: [
    default: true,
    module: BauleBio.Compte.Scope,
    assign_key: :current_scope,
    access_path: [:utilisateur, :id],
    schema_key: :utilisateur_id,
    schema_type: :id,
    schema_table: :utilisateurs,
    test_data_fixture: BauleBio.CompteFixtures,
    test_setup_helper: :register_and_log_in_utilisateur
  ]

config :baule_bio,
  ecto_repos: [BauleBio.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :baule_bio, BauleBioWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BauleBioWeb.ErrorHTML, json: BauleBioWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BauleBio.PubSub,
  live_view: [signing_salt: "T9+qDQXZ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :baule_bio, BauleBio.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  baule_bio: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  baule_bio: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
