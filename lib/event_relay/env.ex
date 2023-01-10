defmodule ER.Env do
  def skip_grpc_auth? do
    System.get_env("ER_SKIP_GRPC_AUTH") == "true"
    true
  end

  def grpc_port do
    ER.to_integer(System.get_env("ER_GRPC_PORT") || "50051")
  end
end
