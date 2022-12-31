defmodule ER do
  @moduledoc """
  ER keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
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
  def empty?(str) when is_binary(str), do: String.trim(str) == ""
  def empty?(map) when is_map(map), do: map == %{}
  def empty?(list) when is_list(list), do: list == []
end
