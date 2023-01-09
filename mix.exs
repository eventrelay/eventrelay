defmodule ER.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_relay,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ER.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.0-rc.0", override: true},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.3"},
      {:heroicons, "~> 0.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      # {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:exsync, "~> 0.2", only: :dev},
      # Rate Limiting - https://github.com/ExHammer/hammer
      {:hammer_backend_redis, "~> 6.1"},
      {:hammer, "~> 6.1"},
      # GRPC - https://github.com/elixir-grpc/grpc
      {:grpc, "~> 0.5.0"},
      {:protobuf, "~> 0.11"},
      # JWT - https://github.com/joken-elixir/joken
      {:joken, "~> 2.5"},
      # Authorization https://github.com/themusicman/bosun
      {:bosun, "~> 1.0.1"},
      # Testing
      {:faker, "~> 0.17"},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:hammox, "~> 0.7", only: :test},
      # Distributed Elixir
      {:horde, "~> 0.8.2"},
      {:libcluster, "~> 3.2"},
      # HTTP Client
      {:httpoison, "~> 1.8"},
      # Redis
      {:redix, "~> 1.2"},
      # Cache
      {:nebulex, "~> 2.4"},
      {:nebulex_adapters_horde, "~> 1.0.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
