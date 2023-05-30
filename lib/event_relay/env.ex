defmodule ER.Env do
  def skip_grpc_auth? do
    System.get_env("ER_SKIP_GRPC_AUTH") == "true"
  end

  def grpc_port do
    Application.get_env(:event_relay, :grpc_port, 50051)
  end
end
