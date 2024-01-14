defmodule ER.S3 do
  alias ExAws.S3

  def put_object!(region, bucket, file_name, data) do
    S3.put_object(bucket, file_name, data) |> ExAws.request!(region: region)
  end
end
