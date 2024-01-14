defmodule ER.Destinations.File.Format.Jsonl do
  defstruct file_extension: "jsonl"

  defimpl ER.Destinations.File.Format do
    def extension(encoder) do
      encoder.file_extension
    end

    def encode(encoder, messages, _opts) do
      encoded =
        Enum.map(messages, fn %{data: event} ->
          case Jason.encode(event) do
            {:ok, json} ->
              json

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.join("\n")

      {encoder, encoded}
    end
  end
end
