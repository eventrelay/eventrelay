defmodule ER.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # dev
    # topologies = [
    #   example: [
    #     strategy: Cluster.Strategy.Epmd,
    #     config: [hosts: [:a@eventrelay]]
    #   ]
    # ]

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

    children =
      [
        # Listen for changes in the nodes
        ER.NodeListener,
        # Start the Telemetry supervisor
        ERWeb.Telemetry,
        # Start the Ecto repository
        ER.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: ER.PubSub},
        # Start the Endpoint (http/https)
        ERWeb.Endpoint,
        # Starts supervisor for Flamel background tasks
        {Task.Supervisor, name: Flamel.Task},
        # Start the GRPC API
        {GRPC.Server.Supervisor, grpc_start_args()},
        # Start the Elixir Process Registry
        {Registry, keys: :unique, name: ER.Registry},
        # Start a DynamicSupervisor for our application
        {DynamicSupervisor, strategy: :one_for_one, name: ER.DynamicSupervisor},
        {ER.Horde.Registry, [name: ER.Horde.Registry, shutdown: 60_000, keys: :unique]},
        {ER.Horde.Supervisor,
         [name: ER.Horde.Supervisor, shutdown: 60_000, strategy: :one_for_one]},
        # Start the Cluster server
        # {Cluster.Supervisor, [topologies, [name: ER.ClusterSupervisor]]},
        # Setup the Cache
        {ER.Cache, []},
        # Setup the ChannelCache
        {ER.Events.ChannelCache, []},
        # Setup the ApiKeyCache
        {ER.Accounts.ApiKeyCache, []},
        # Start the server that monitor Phoenix channels connections
        {ER.ChannelMonitor, :events}
      ]
      |> add_child(ER.BootServer)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ER.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp add_child(children, child), do: children ++ [child]

  defp grpc_start_args() do
    opts = [endpoint: ERWeb.Grpc.Endpoint, port: ER.Env.grpc_port()]

    opts =
      if ER.Env.use_grpc_tls?() do
        {_type, grpc_server_crt} =
          ER.Env.grpc_server_crt()
          |> ER.CA.to_der()

        grpc_server_key =
          ER.Env.grpc_server_key()
          |> ER.CA.to_der()

        {_type, ca_crt} =
          ER.Env.ca_crt()
          |> ER.CA.to_der()

        cred =
          GRPC.Credential.new(
            ssl: [
              cert: grpc_server_crt,
              key: grpc_server_key,
              cacerts: [ca_crt],
              secure_renegotiate: true,
              reuse_sessions: true,
              verify: :verify_peer,
              fail_if_no_peer_cert: true
            ]
          )

        Keyword.merge(opts, cred: cred)
      else
        opts
      end

    opts =
      if Code.ensure_loaded?(IEx) and IEx.started?() do
        opts
      else
        Keyword.merge(opts, start_server: true)
      end

    Logger.debug("GRPC Server opts: #{inspect(opts)}")
    opts
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ERWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
