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
end
