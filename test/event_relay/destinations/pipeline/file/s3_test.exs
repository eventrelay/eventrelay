defmodule ER.Destinations.Pipeline.File.S3Test do
  use ER.DataCase
  alias ER.Destinations.File.S3

  describe "build_events_file_name/1" do
    test "returns file name that includes date as a dir and ISO8601 in the file name" do
      now = ~U[2023-01-01 00:00:00Z]

      assert S3.build_events_file_name("jsonl", now) ==
               "/2023-01-01/2023-01-01T00:00:00Z-events.jsonl"
    end
  end
end
