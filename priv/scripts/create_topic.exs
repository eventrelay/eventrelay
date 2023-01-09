{:ok, channel} = GRPC.Stub.connect("localhost:50051")
request = ERWeb.Grpc.Eventrelay.CreateTopicRequest.new(name: "grpc-elixir")
{:ok, reply} = channel |> ERWeb.Grpc.Eventrelay.EventRelay.Stub.create_topic(request)
IO.inspect(reply)
