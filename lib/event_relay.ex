defmodule ER do
  @moduledoc """
  ER keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger

  def test?() do
    Application.get_env(:event_relay, :environment) == :test
  end

  def dev?() do
    Application.get_env(:event_relay, :environment) == :dev
  end

  def prod?() do
    Application.get_env(:event_relay, :environment) == :prod
  end

  def to_integer(value) when is_binary(value) do
    String.to_integer(value)
  end

  def to_integer(value) when is_integer(value) do
    value
  end

  def to_integer(value) when is_float(value) do
    Float.to_string(value) |> to_integer()
  end

  def to_integer(value) when is_nil(value) do
    0
  end

  def to_float(value) when is_binary(value) do
    value
    |> Float.parse()
    |> case do
      {value, _} ->
        value

      _ ->
        0.0
    end
  end

  def to_float(value) when is_float(value) do
    value
  end

  def to_float(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> to_float()
  end

  def to_float(%Decimal{} = value) do
    Decimal.to_float(value)
  end

  def to_float(value) when is_nil(value) do
    0
  end

  def to_map(value) when is_struct(value) do
    Map.from_struct(value)
  end

  def to_map(value) when is_map(value) do
    value
  end

  def to_datetime(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, start, _} ->
        start

      _ ->
        nil
    end
  end

  def to_datetime(%DateTime{} = datetime) do
    datetime
  end

  def to_datetime(%NaiveDateTime{} = datetime) do
    datetime
  end

  def to_datetime(_) do
    nil
  end

  def to_iso8601(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end

  def to_iso8601(%NaiveDateTime{} = datetime) do
    NaiveDateTime.to_iso8601(datetime)
  end

  def to_iso8601(_) do
    ""
  end

  @doc """
  Takes an {:ok, value} tuple and returns the value

  Examples

  iex> ER.unwrap_ok!({:ok, 1})
  1

  iex> ER.unwrap_ok!({:error, 1})
  ** (ArgumentError) {:error, 1} is not an :ok tuple
  """
  def unwrap_ok!({:ok, value}) do
    value
  end

  def unwrap_ok!(value) do
    raise ArgumentError, message: "#{inspect(value)} is not an :ok tuple"
  end

  def unwrap_ok_or_nil({:ok, value}) do
    value
  end

  def unwrap_ok_or_nil(_) do
    nil
  end

  def unwrap({:ok, value}), do: value
  def unwrap({:error, value}), do: value

  @doc """
  Check if something is empty

  iex> ER.empty?(nil)
  true

  iex> ER.empty?("hi")
  false

  iex> ER.empty?("   \t   ")
  true

  iex> ER.empty?(%{})
  true

  iex> ER.empty?(%{a: 1})
  false

  iex> ER.empty?([])
  true

  iex> ER.empty?(["a"])
  false
  """
  def empty?(nil), do: true
  def empty?(0), do: true
  def empty?(integer) when is_integer(integer), do: false
  def empty?(str) when is_binary(str), do: String.trim(str) == ""
  def empty?([]), do: true
  def empty?(map) when map == %{}, do: true
  def empty?(%DateTime{}), do: false
  def empty?(_), do: false

  def boolean?(value) when is_boolean(value), do: true
  def boolean?(value) when not is_boolean(value), do: false

  @doc """
  Convert something to a boolean

  iex> ER.to_boolean("Y")
  true

  iex> ER.to_boolean("y")
  true

  iex> ER.to_boolean("YES")
  true

  iex> ER.to_boolean("Yes")
  true

  iex> ER.to_boolean("yes")
  true

  iex> ER.to_boolean("true")
  true

  iex> ER.to_boolean(1)
  true

  iex> ER.to_boolean(true)
  true 

  iex> ER.to_boolean("N")
  false

  iex> ER.to_boolean("n")
  false

  iex> ER.to_boolean("NO")
  false

  iex> ER.to_boolean("No")
  false

  iex> ER.to_boolean("no")
  false

  iex> ER.to_boolean("false")
  false

  iex> ER.to_boolean(0)
  false

  iex> ER.to_boolean(false)
  false
  """
  def to_boolean("Y"), do: true
  def to_boolean("y"), do: true
  def to_boolean("YES"), do: true
  def to_boolean("Yes"), do: true
  def to_boolean("yes"), do: true
  def to_boolean("true"), do: true
  def to_boolean("1"), do: true
  def to_boolean(1), do: true
  def to_boolean(true), do: true
  def to_boolean("N"), do: false
  def to_boolean("n"), do: false
  def to_boolean("NO"), do: false
  def to_boolean("No"), do: false
  def to_boolean("no"), do: false
  def to_boolean("false"), do: false
  def to_boolean("0"), do: false
  def to_boolean(0), do: false
  def to_boolean(false), do: false
  def to_boolean(nil), do: false
  def to_boolean(_), do: false

  @doc """
  Converts the top level keys in a map from atoms to strings

  ## Examples

      iex> Blockit.stringify_map(%{a: 1, b: 2})
      %{"a" => 1, "b" => 2}

      iex> Blockit.stringify_map(%{"a" => 1, "b" => 2})
      %{"a" => 1, "b" => 2}


  """
  def stringify_map(value) when is_map(value) do
    value
    |> Map.new(fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} when is_binary(k) -> {k, v}
    end)
  end

  @doc """
  Converts the top level keys in a map from string to atoms

  ## Examples

      iex> Blockit.stringify_map(%{a: 1, b: 2})
      %{"a" => 1, "b" => 2}

      iex> Blockit.stringify_map(%{"a" => 1, "b" => 2})
      %{"a" => 1, "b" => 2}


  """
  def atomize_map(value) when is_map(value) do
    value
    |> Map.new(fn
      {k, v} when is_atom(k) -> {k, v}
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
    end)
  end

  @doc """
  Allows you to access a value "safely"
  """
  @spec safely_get(map() | struct(), function() | atom()) :: any()
  def safely_get(var, func) do
    safely_get(var, func, "")
  end

  @spec safely_get(map() | struct(), function() | atom(), any()) :: any()
  def safely_get(var, func, default) when is_function(default) do
    try do
      safely_get(var, func, default.(var))
    rescue
      e in KeyError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        nil

      e in RuntimeError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        nil
    end
  end

  def safely_get(var, field, default) when is_atom(field) or is_binary(field) do
    try do
      if var do
        indifferent_get(var, field, default)
      else
        default
      end
    rescue
      e in BadMapError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        default

      e in RuntimeError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        default
    end
  end

  def safely_get(var, func, default) when is_function(func) do
    try do
      if var do
        func.(var)
      else
        default
      end
    rescue
      e in KeyError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        default

      e in RuntimeError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        default
    end
  end

  @spec indifferent_get(map(), atom() | binary(), any()) :: any()
  def indifferent_get(map, key, default \\ nil)

  def indifferent_get(map, key, default) when is_atom(key) do
    Map.get(map, key, Map.get(map, to_string(key), default))
  end

  def indifferent_get(map, key, default) when is_binary(key) do
    Map.get(map, key, Map.get(map, String.to_existing_atom(key), default))
  end
end
