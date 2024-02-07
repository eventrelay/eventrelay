defmodule ER.Events.Predicates do
  import Ecto.Query

  def apply_predicates([predicate | predicates], nil, nil) do
    # first iteration
    conditions = apply_predicate(predicate, dynamic(true), nil)
    apply_predicates(predicates, conditions, predicate)
  end

  def apply_predicates([predicate | predicates], conditions, previous_predicate) do
    conditions = apply_predicate(predicate, conditions, previous_predicate)
    apply_predicates(predicates, conditions, predicate)
  end

  def apply_predicates([], conditions, _previous_predicate) do
    conditions
  end

  def apply_predicate(%{predicates: predicates}, conditions, previous_predicate)
      when length(predicates) > 0 do
    nested_conditions = apply_predicates(predicates, dynamic(true), previous_predicate)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and ^nested_conditions)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and ^nested_conditions)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or ^nested_conditions)
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: "==", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) == ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) == ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) == ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: "==",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) == ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) == ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) == ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: "==", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) == ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) == ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) == ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: "!=", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) != ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) != ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) != ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: "!",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) != ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) != ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) != ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: "!=", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) != ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) != ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) != ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: "<", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) < ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) < ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) < ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: "<",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) < ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) < ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) < ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: "<", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) < ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) < ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) < ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: "<=", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) <= ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) <= ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) <= ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: "<=",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) <= ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) <= ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) <= ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: "<=", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) <= ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) <= ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) <= ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: ">", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) > ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) > ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) > ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: ">",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) > ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) > ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) > ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: ">", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) > ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) > ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) > ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: ">=", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) >= ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) >= ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) >= ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: ">=",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) >= ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) >= ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) >= ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: ">=", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) >= ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) >= ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) >= ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: "data." <> path, comparison_operator: "in", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) in ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and json_extract_path(events.data, ^path) in ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or json_extract_path(events.data, ^path) in ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{
            identifier: "context." <> path,
            comparison_operator: "in",
            expression: value
          }
        },
        conditions,
        previous_predicate
      ) do
    path = parse_path(path)

    case previous_predicate do
      nil ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) in ^value
        )

      %{logical_operator: :and} ->
        dynamic(
          [events: events],
          ^conditions and json_extract_path(events.context, ^path) in ^value
        )

      %{logical_operator: :or} ->
        dynamic(
          [events: events],
          ^conditions or json_extract_path(events.context, ^path) in ^value
        )

      _ ->
        conditions
    end
  end

  def apply_predicate(
        %{
          condition: %{identifier: field, comparison_operator: "in", expression: value}
        },
        conditions,
        previous_predicate
      ) do
    field = String.to_existing_atom(field)

    case previous_predicate do
      nil ->
        dynamic([events: events], ^conditions and field(events, ^field) in ^value)

      %{logical_operator: :and} ->
        dynamic([events: events], ^conditions and field(events, ^field) in ^value)

      %{logical_operator: :or} ->
        dynamic([events: events], ^conditions or field(events, ^field) in ^value)

      _ ->
        conditions
    end
  end

  def apply_predicate(_predicate, conditions, _previous_predicate) do
    conditions
  end

  def parse_path(path) do
    String.split(path, ".", trim: true)
    |> Enum.map(&String.trim/1)
  end
end
