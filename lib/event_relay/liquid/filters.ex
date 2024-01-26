defmodule ER.Liquid.Filters do
  use Liquex.Filter

  def json(value, _) do
    Jason.encode!(value)
  end

  def get(value, key, default \\ "", _) when is_map(value) do
    Map.get(value, key, default)
  end

  def get_in(value, path, _) when is_map(value) do
    keys = String.split(path, ".") |> Enum.map(&Flamel.to_string/1)
    get_in(value, keys)
  end
end
