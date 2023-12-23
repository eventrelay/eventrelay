import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/event_relay start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :event_relay, ERWeb.Endpoint, server: true
end

config :ex_aws, :s3,
  scheme: System.get_env("ER_S3_SCHEME", "http://"),
  host: System.get_env("ER_S3_HOST", "localhost"),
  port: System.get_env("ER_S3_PORT", "9000")

config :hammer,
  backend: [
    ets: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]},
    redis:
      {Hammer.Backend.Redis,
       [
         delete_buckets_timeout: 10_0000,
         expiry_ms: 60_000 * 60 * 2,
         redis_url: System.get_env("ER_REDIS_URL")
       ]}
  ]

config :event_relay, :ca_key, System.get_env("ER_CA_KEY")
config :event_relay, :ca_crt, System.get_env("ER_CA_CRT")
config :event_relay, :grpc_server_key, System.get_env("ER_GRPC_SERVER_KEY")
config :event_relay, :grpc_server_crt, System.get_env("ER_GRPC_SERVER_CRT")
config :event_relay, :hammer_backend, System.get_env("ER_HAMMER_BACKEND")

if config_env() == :dev do
  database_url =
    System.get_env("ER_DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  # Configure your database
  config :event_relay, ER.Repo,
    url: database_url,
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10
end

if config_env() == :test do
  database_url =
    System.get_env("ER_TEST_DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  # Configure your database
  config :event_relay, ER.Repo,
    url: database_url,
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10
end

if config_env() == :prod do
  config :event_relay, :grpc_port, ER.to_integer(System.get_env("ER_GRPC_PORT") || "50051")

  database_url =
    System.get_env("ER_DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :event_relay, ER.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "9000")

  config :event_relay, ERWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :event_relay, ERWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :event_relay, ERWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :event_relay, ER.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
  #
  config :event_relay, :jwt_secret, System.get_env("ER_JWT_SECRET")
end

config :event_relay, :account_key, System.get_env("ER_ACCOUNT_KEY")
