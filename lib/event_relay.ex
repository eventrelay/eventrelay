defmodule ER do
  @moduledoc """
  ER keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def test?() do
    Application.get_env(:event_relay, :environment) == :test
  end

  def dev?() do
    Application.get_env(:event_relay, :environment) == :dev
  end

  def prod?() do
    Application.get_env(:event_relay, :environment) == :prod
  end

  def to_string(value) when is_binary(value) do
    value
  end

  def to_string(value) when is_integer(value) do
    Integer.to_string(value)
  end

  def to_string(value) when is_float(value) do
    Float.to_string(value)
  end

  def to_string(value) when is_atom(value) do
    Atom.to_string(value)
  end

  def to_string(value) when is_nil(value) do
    ""
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
  def empty?(map) when is_map(map), do: map == %{}
  def empty?(list) when is_list(list), do: list == []

  def boolean?(value) when is_boolean(value), do: true
  def boolean?(value) when not is_boolean(value), do: false
end
