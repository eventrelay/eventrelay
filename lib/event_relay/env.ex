defmodule ER.Env do
  def disable_push_destinations? do
    Flamel.to_boolean(System.get_env("ER_DISABLE_PUSH_DESTINATIONS")) == true
  end

  def skip_grpc_auth? do
    Flamel.to_boolean(System.get_env("ER_SKIP_GRPC_AUTH")) == true
  end

  def use_grpc_tls? do
    Flamel.to_boolean(System.get_env("ER_USE_GRPC_TLS") || true) == true
  end

  def use_redis? do
    hammer_backend() == "redis"
  end

  def grpc_port do
    Application.get_env(:event_relay, :grpc_port, 50051)
  end

  def grpc_server_key do
    Application.get_env(:event_relay, :grpc_server_key) |> trim()
  end

  def grpc_server_crt do
    Application.get_env(:event_relay, :grpc_server_crt) |> trim()
  end

  def debug_transformers do
    Application.get_env(:event_relay, :debug_transformers, false)
  end

  def ca_key do
    Application.get_env(:event_relay, :ca_key) |> trim()
  end

  def ca_crt do
    Application.get_env(:event_relay, :ca_crt) |> trim()
  end

  def hammer_backend do
    Application.get_env(:event_relay, :hammer_backend, "ETS")
    |> trim()
    |> String.downcase()
  end

  defp trim(value) do
    value
    |> to_string()
    |> String.trim()
  end
end
