# {:ok,
#  %ER.Accounts.ApiKey{
#    __meta__: #Ecto.Schema.Metadata<:loaded, "api_keys">,
#    id: "08c1b381-8b25-4132-8602-174734b6307c",
#    key: "p3z6humPYYW6cLZDrdqfFn_MDHtnw9lAUcnYG_P2qn",
#    secret: "y7XN9MIChpxHyERA-dc8IFpDTkCWSstv1AKrvQs9guIbo5DOt1w5kg-qmT56kYZs",
#    status: :active,
#    type: :producer,
#    api_key_subscriptions: #Ecto.Association.NotLoaded<association :api_key_subscriptions is not loaded>,
#    subscriptions: #Ecto.Association.NotLoaded<association :subscriptions is not loaded>,
#    inserted_at: ~U[2023-01-07 09:49:55Z],
#    updated_at: ~U[2023-01-07 09:49:55Z]
#  }}
{:ok, channel} =
  GRPC.Stub.connect("localhost:50051",
    headers: [
      {"Authorization",
       "Bearer cDN6Nmh1bVBZWVc2Y0xaRHJkcWZGbl9NREh0bnc5bEFVY25ZR19QMnFuOnk3WE45TUlDaHB4SHlFUkEtZGM4SUZwRFRrQ1dTc3R2MUFLcnZRczlndUlibzVET3QxdzVrZy1xbVQ1NmtZWnM="}
    ]
  )

request = ERWeb.Grpc.Eventrelay.ListTopicsRequest.new()
{:ok, reply} = channel |> ERWeb.Grpc.Eventrelay.EventRelay.Stub.list_topics(request)
IO.inspect(reply)
