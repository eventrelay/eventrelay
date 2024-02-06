defmodule ER.Destinations.Pipeline do
  alias ER.Destinations.Destination

  def factory(%Destination{destination_type: :file} = _destination),
    do: ER.Destinations.Pipeline.File

  def factory(%Destination{destination_type: :webhook} = _destination),
    do: ER.Destinations.Pipeline.Webhook

  def factory(%Destination{destination_type: :topic} = _destination),
    do: ER.Destinations.Pipeline.Topic

  def factory(%Destination{destination_type: :database} = _destination),
    do: ER.Destinations.Pipeline.Database

  def factory(_), do: nil
end
