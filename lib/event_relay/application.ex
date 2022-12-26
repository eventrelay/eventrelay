defmodule ER.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
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
      # Start a worker by calling: ER.Worker.start_link(arg)
      # {ER.Worker, arg}
      {GRPC.Server.Supervisor, {ERWeb.Grpc.Endpoint, 90001}}
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
