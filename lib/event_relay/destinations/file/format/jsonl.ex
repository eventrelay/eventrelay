defmodule ER.Destinations.File.Format.Jsonl do
  defstruct file_extension: "jsonl"

  defimpl ER.Destinations.File.Format do
    alias ER.Transformers.Transformer
    alias ER.Events.Event

    def extension(encoder) do
      encoder.file_extension
    end

    def encode(encoder, messages, destination, _opts) do
      encoded =
        Enum.reduce(messages, "", fn %{data: event}, acc ->
          event
          |> Event.to_map()
          |> Transformer.transform(destination)
          |> Map.put_new("id", event.id)
          |> encode_data(acc)
        end)

      {encoder, encoded}
    end

    defp encode_data(data, acc) do
      case Jason.encode(data) do
        {:ok, json} ->
          case acc do
            "" ->
              acc <> json

            _ ->
              acc <> "\n" <> json
          end

        _ ->
          acc
      end
    end
  end
end
