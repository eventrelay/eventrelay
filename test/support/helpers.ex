defmodule ER.Test.Helpers do
  alias Broadway.Message

  def parse_jsonl(jsonl) do
    Enum.map(String.split(jsonl, "\n", trim: true), fn line ->
      Jason.decode!(line)
    end)
  end

  def build_broadway_message(event) do
    %Message{data: event, acknowledger: Broadway.NoopAcknowledger.init()}
  end
end
