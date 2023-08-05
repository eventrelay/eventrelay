defmodule ER.S3Behavior do
  @callback put_object(binary(), binary(), binary()) :: {:ok, any()} | {:error, binary()}
end

defmodule ER.S3 do
  require Logger
  alias ExAws.S3
  @behaviour ER.S3Behavior

  @impl true
  def put_object(bucket, file_name, data) do
    try do
      S3.put_object(bucket, file_name, data) |> ExAws.request!()
    rescue
      e in RuntimeError ->
        Logger.error("ER.S3.put_object exception=#{inspect(e)}")

        Logger.error(Exception.format(:error, e, __STACKTRACE__))
    end
  end
end
