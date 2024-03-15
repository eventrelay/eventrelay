defmodule ER.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_relay,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ER.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
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
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.3"},
      {:calendar, "~> 1.0.0"},
      {:heroicons, "~> 0.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:exsync, "~> 0.2", only: :dev},
      {:horde, "~> 0.8"},
      # Rate Limiting - https://github.com/ExHammer/hammer
      {:hammer_backend_redis, "~> 6.1"},
      {:hammer, "~> 6.1"},
      # GRPC - https://github.com/elixir-grpc/grpc
      {:grpc, "~> 0.7"},
      {:protobuf, "~> 0.11"},
      # JWT - https://github.com/joken-elixir/joken
      {:joken, "~> 2.5"},
      # Authorization https://github.com/themusicman/bosun
      {:bosun, "~> 1.0.1"},
      # Testing
      {:faker, "~> 0.17"},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      # Distributed Elixir
      {:libcluster, "~> 3.2"},
      # HTTP Client
      {:req, "~> 0.4"},
      # Cache
      {:nebulex, "~> 2.4"},
      {:nebulex_adapters_horde, "~> 1.0.0"},
      {:decorator, "~> 1.4"},

      # AWS
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},

      # GCP
      {:broadway_cloud_pub_sub, "~> 0.7"},
      {:goth, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6.6"},
      {:exlua, github: "themusicman/exlua", branch: "master"},
      {:luerl, "~> 0.3"},

      # Benchmarking
      {:benchee, "~> 1.0", only: :dev},
      {:predicated, github: "themusicman/predicated", branch: "main"},
      # {:predicated, path: "/home/tbrewer/projects/predicated"},
      {:flamel, github: "themusicman/flamel", branch: "main"},
      {:off_broadway_ecto, github: "eventrelay/offbroadway_ecto", branch: "main"},

      # Certificate Authority/TLS
      {:x509, "~> 0.8"},
      {:ex_json_schema, "~> 0.10.2"},
      {:liquex, "~> 0.11.0"},
      {:broadway_dashboard, "~> 0.4.0"},
      {:mimic, "~> 1.7", only: :test},
      {:petal_components, "~> 1.8"},

      # Code Quality
      {:ex_check, "~> 0.14.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false},
      {:webhoox, "~> 0.3.0"},
      {:uniq, "~> 0.1"}
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
