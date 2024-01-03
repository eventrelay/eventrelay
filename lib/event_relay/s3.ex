defmodule ER.S3Behavior do
  @callback put_object!(binary(), binary(), binary(), binary()) ::
              {:ok, any()} | {:error, binary()}
end

defmodule ER.S3 do
  require Logger
  alias ExAws.S3
  @behaviour ER.S3Behavior

  @impl true
  def put_object!(region, bucket, file_name, data) do
    S3.put_object(bucket, file_name, data) |> ExAws.request!(region: region)
  end
end
