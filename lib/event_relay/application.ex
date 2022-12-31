defmodule ER.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # dev
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:a@eventrelay]]
      ]
    ]

    # prod
    # [
    #   k8s: [
    #     strategy: Elixir.Cluster.Strategy.Kubernetes,
    #     config: [
    #       mode: :hostname,
    #       kubernetes_node_basename: "eventrelay",
    #       kubernetes_service_name: "eventrelay-service",
    #       kubernetes_selector: "app=eventrelay"
    #       # Convert to env var
    #       kubernetes_namespace: "default",
    #       polling_interval: 5_000
    #     ]
    #   ]
    # ]

    children = [
      # Start the Telemetry supervisor
      ERWeb.Telemetry,
      # Start the Ecto repository
      ER.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ER.PubSub},
      # Start Finch
      {Finch, name: ER.Finch},
      # Start the Endpoint (http/https)
      ERWeb.Endpoint,
      {GRPC.Server.Supervisor, {ERWeb.Grpc.Endpoint, 50051}},
      {Cluster.Supervisor, [topologies, [name: ER.ClusterSupervisor]]},
      ER.NodeListener,
      {ER.Horde.Registry, [name: ER.Horde.Registry, shutdown: 60_000, keys: :unique]},
      {ER.Horde.Supervisor, [name: ER.Horde.Supervisor, shutdown: 60_000, strategy: :one_for_one]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ER.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ERWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
