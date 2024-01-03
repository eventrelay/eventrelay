defmodule ER.Destinations.Pipeline do
  alias ER.Destinations.Destination

  def factory(%Destination{destination_type: :s3} = _destination), do: ER.Destinations.Pipeline.S3

  def factory(%Destination{destination_type: :webhook} = _destination),
    do: ER.Destinations.Pipeline.Webhook

  def factory(%Destination{destination_type: :topic} = _destination),
    do: ER.Destinations.Pipeline.Topic

  def factory(_), do: nil
end
