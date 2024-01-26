defmodule ER.Destinations.File.Format.Jsonl do
  defstruct file_extension: "jsonl"

  defimpl ER.Destinations.File.Format do
    alias ER.Destinations.Destination
    alias ER.Events.Event

    def extension(encoder) do
      encoder.file_extension
    end

    def encode(encoder, messages, destination, _opts) do
      encoded =
        Enum.map(messages, fn %{data: event} ->
          data =
            event
            |> Event.to_map()
            |> Destination.transform_event(destination)
            |> Map.put_new("id", event.id)

          case Jason.encode(data) do
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
