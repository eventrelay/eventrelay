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
        # Start the Telemetry supervisor
        ERWeb.Telemetry,
        # Start the Ecto repository
        ER.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: ER.PubSub},
        # Start the Endpoint (http/https)
        ERWeb.Endpoint,
        {GRPC.Server.Supervisor, grpc_start_args()},
        # {Cluster.Supervisor, [topologies, [name: ER.ClusterSupervisor]]},
        {ER.Events.ChannelCache, []},
        ER.NodeListener,
        {ER.Horde.Registry, [name: ER.Horde.Registry, shutdown: 60_000, keys: :unique]},
        {ER.Horde.Supervisor,
         [name: ER.Horde.Supervisor, shutdown: 60_000, strategy: :one_for_one]},
        {ER.ChannelMonitor, :events},
        ER.BootServer
      ]
      |> maybe_add_child(ER.Env.use_redis?(), ER.Redix)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ER.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_add_child(children, true, child), do: children ++ [child]
  defp maybe_add_child(children, false, _child), do: children

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
      unless Code.ensure_loaded?(IEx) and IEx.started?() do
        Keyword.merge(opts, start_server: true)
      else
        opts
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
