defmodule ER.Env do
  def skip_grpc_auth? do
    System.get_env("ER_SKIP_GRPC_AUTH") == "true"
  end

  def grpc_port do
    Application.get_env(:event_relay, :grpc_port, 50051)
  end

  def grpc_server_key do
    Application.get_env(:event_relay, :grpc_server_key) |> String.trim()
  end

  def grpc_server_crt do
    Application.get_env(:event_relay, :grpc_server_crt) |> String.trim()
  end

  def debug_transformers do
    Application.get_env(:event_relay, :debug_transformers, false)
  end

  def ca_key do
    Application.get_env(:event_relay, :ca_key) |> String.trim()
  end

  def ca_crt do
    Application.get_env(:event_relay, :ca_crt) |> String.trim()
  end
end
