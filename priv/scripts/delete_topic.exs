{:ok, channel} = GRPC.Stub.connect("localhost:50051")
request = ERWeb.Grpc.Eventrelay.DeleteTopicRequest.new(id: "d8398e99-5e20-4e36-9bd0-ff95ad5d7672")
{:ok, reply} = channel |> ERWeb.Grpc.Eventrelay.EventRelay.Stub.delete_topic(request)
IO.inspect(reply)
