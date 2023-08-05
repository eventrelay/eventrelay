defmodule ER.Test.Helpers do
  def parse_jsonl(jsonl) do
    Enum.map(String.split(jsonl, "\n", trim: true), fn line ->
      Jason.decode!(line)
    end)
  end
end
