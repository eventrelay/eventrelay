defmodule ERWeb.Grpc.Enums do
  def to_grpc_enum(value) do
    value |> to_string() |> String.upcase() |> String.to_atom()
  end

  def from_grpc_enum(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.to_atom()
  end
end
