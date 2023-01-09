defmodule ER.Env do
  def skip_grpc_auth? do
    Application.get_env(:event_relay, :skip_grpc_auth)
  end

  def grpc_port do
    ER.to_integer(System.get_env("ER_GRPC_PORT") || "50051")
  end
end
