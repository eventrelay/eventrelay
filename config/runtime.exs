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

if config_env() == :prod do
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

  host = System.get_env("ER_WEB_HOST") || "example.com"
  port = String.to_integer(System.get_env("ER_WEB_PORT") || "9000")

  endpoint_opts =
    [
      secret_key_base: secret_key_base
    ]
    |> then(fn opts ->
      if System.get_env("ER_USE_WEB_TLS") do
        opts
        |> Keyword.put(
          :https,
          [
            port: port,
            cipher_suite: :strong,
            keyfile: System.get_env("ER_WEB_TLS_KEY_PATH"),
            certfile: System.get_env("ER_WEB_TLS_CRT_PATH")
          ],
          force_ssl: [hsts: true]
        )
        |> Keyword.put(:url, host: host, port: port, scheme: "https")
      else
        opts
        |> Keyword.put(:http, ip: {0, 0, 0, 0}, port: port)
        |> Keyword.put(:url, host: host, port: 443, scheme: "http")
      end
    end)

  config :event_relay, ERWeb.Endpoint, endpoint_opts

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
end

database_url =
  System.get_env("ER_DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

db_opts =
  cond do
    config_env() == :dev ->
      [
        url: database_url,
        stacktrace: true,
        show_sensitive_data_on_connection_error: true,
        pool_size: 10
      ]

    config_env() == :test ->
      test_database_url =
        System.get_env("ER_TEST_DATABASE_URL") ||
          raise """
          environment variable DATABASE_URL is missing.
          For example: ecto://USER:PASS@HOST/DATABASE
          """

      [
        url: test_database_url,
        stacktrace: true,
        show_sensitive_data_on_connection_error: true,
        pool_size: 10
      ]

    true ->
      maybe_ipv6 = if System.get_env("ER_ECTO_IPV6"), do: [:inet6], else: []

      [
        url: database_url,
        pool_size: String.to_integer(System.get_env("ER_DATABASE_POOL_SIZE") || "10"),
        socket_options: maybe_ipv6
      ]
  end

config :event_relay, ER.Repo, db_opts

config :event_relay, :jwt_secret, System.get_env("ER_JWT_SECRET")

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
config :event_relay, :account_key, System.get_env("ER_ACCOUNT_KEY")

if System.get_env("ER_WEB_SERVER") do
  config :event_relay, ERWeb.Endpoint, server: true
end
