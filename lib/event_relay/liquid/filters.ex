defmodule ER.Liquid.Filters do
  use Liquex.Filter

  def json(value, _) do
    Jason.encode!(value)
  end
end
