defmodule ER.Destinations.File.Formatter do
  alias ER.Destinations.File.Format

  def factory("jsonl") do
    %Format.Jsonl{}
  end

  def factory(_) do
    %Format.Jsonl{}
  end
end
