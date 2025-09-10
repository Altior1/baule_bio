import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1
username = System.get_env("PHX_DBUSER") || raise "username not defined"
password = System.get_env("PHX_DBPASSWORD") || raise "password not defined"
hostname = System.get_env("PHX_DBHOST") || raise "hostname not defined"
database = System.get_env("PHX_DBNAME") || raise "database not defined"
port = System.get_env("PHX_DBPORT") || "5432"

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :baule_bio, BauleBio.Repo,
  username: username,
  password: password,
  hostname: hostname,
  database: database,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :baule_bio, BauleBioWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "hvyldsPeq8FXKNl7NAgYGjTj94vqaR7e4fqN8KMaYtAWSAfeib4sN+LlCo2NySxe",
  server: false

# In test we don't send emails
config :baule_bio, BauleBio.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
