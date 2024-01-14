defmodule ER.Predicates do
  def to_predicates(query) when is_binary(query) do
    if Flamel.present?(query) do
      case Predicated.Query.new(query) do
        {:ok, predicates} -> predicates
        _ -> []
      end
    else
      []
    end
  end

  def to_predicates(value) when is_list(value), do: value

  def to_predicates(_), do: []
end
