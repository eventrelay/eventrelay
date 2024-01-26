defmodule ER.Destinations.File.S3 do
  defstruct destination: nil

  def build_events_file_name(file_extension, now) do
    datetime = now |> DateTime.to_iso8601()
    folder = now |> DateTime.to_date() |> Date.to_string()
    "/#{folder}/#{datetime}-events.#{file_extension}"
  end

  defimpl ER.Destinations.File do
    alias ER.Destinations.File.S3
    require Logger

    def put(
          %{
            destination:
              %{
                config: %{
                  "region" => region,
                  "bucket" => bucket,
                  "access_key_id" => access_key_id,
                  "secret_access_key" => secret_access_key,
                  "format" => format
                }
              } = destination
          },
          messages,
          opts
        )
        when is_list(opts) do
      format
      |> ER.Destinations.File.Formatter.factory()
      |> ER.Destinations.File.Format.encode(messages, destination, opts)
      |> then(fn {encoder, encoded} ->
        ext = ER.Destinations.File.Format.extension(encoder)
        now = Keyword.get(opts, :now, DateTime.utc_now())
        filename = S3.build_events_file_name(ext, now)

        ExAws.S3.put_object(bucket, filename, encoded)
        |> ExAws.request!(
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )

        Logger.debug(
          "#{__MODULE__}.put(#{inspect(encoder)}, #{inspect(messages)} successfully uploaded to S3."
        )
      end)

      messages
    end

    def put(service, messages, opts) do
      Logger.error(
        "#{__MODULE__}.put(#{inspect(service)}, #{inspect(messages)}, #{inspect(opts)}) could not upload the file."
      )

      messages
    end
  end
end
