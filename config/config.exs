# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :albuminum, :scopes,
  user: [
    default: true,
    module: Albuminum.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Albuminum.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :albuminum,
  ecto_repos: [Albuminum.Repo],
  generators: [timestamp_type: :utc_datetime],
  google_photos_picker: Albuminum.GooglePhotosPicker

# Configure the endpoint
config :albuminum, AlbuminumWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AlbuminumWeb.ErrorHTML, json: AlbuminumWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Albuminum.PubSub,
  live_view: [signing_salt: "IVqKScMQ"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :albuminum, Albuminum.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  albuminum: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  albuminum: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Google OAuth configuration (overridden in dev.exs and runtime.exs)
config :albuminum, Albuminum.OAuth.Google,
  client_id: nil,
  client_secret: nil,
  redirect_uri: nil

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
