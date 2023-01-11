defmodule ERWeb.Grpc.Eventrelay.Topic do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.ListTopicsRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :page, 1, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.ListTopicsResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :topics, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.CreateTopicRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :name, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateTopicResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :topic, 1, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :topic, 1, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.NewSubscription.ConfigEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.NewSubscription do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :name, 1, type: :string
  field :topicName, 2, type: :string
  field :topicIdentifier, 3, type: :string
  field :push, 4, type: :bool

  field :config, 6,
    repeated: true,
    type: ERWeb.Grpc.Eventrelay.NewSubscription.ConfigEntry,
    map: true

  field :paused, 7, type: :bool
  field :subscriptionType, 8, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Subscription.ConfigEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Subscription do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topicName, 3, type: :string
  field :topicIdentifier, 4, type: :string
  field :push, 5, type: :bool

  field :config, 7,
    repeated: true,
    type: ERWeb.Grpc.Eventrelay.Subscription.ConfigEntry,
    map: true

  field :paused, 8, type: :bool
  field :subscriptionType, 9, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.ListSubscriptionsRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :page, 1, type: :int32
  field :pageSize, 2, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.ListSubscriptionsResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :subscriptions, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Subscription
  field :totalCount, 2, type: :int32
  field :nextPage, 3, type: :int32
  field :previousPage, 4, type: :int32
  field :totalPages, 5, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.GetSubscriptionRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetSubscriptionResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.Subscription
end

defmodule ERWeb.Grpc.Eventrelay.CreateSubscriptionRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.NewSubscription
end

defmodule ERWeb.Grpc.Eventrelay.CreateSubscriptionResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.Subscription
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.Subscription
end

defmodule ERWeb.Grpc.Eventrelay.NewEvent.ContextEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.NewEvent do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :name, 1, type: :string
  field :data, 2, type: :string
  field :source, 3, type: :string
  field :userId, 4, type: :string
  field :anonymousId, 5, type: :string
  field :occurredAt, 6, type: :string
  field :context, 7, repeated: true, type: ERWeb.Grpc.Eventrelay.NewEvent.ContextEntry, map: true
end

defmodule ERWeb.Grpc.Eventrelay.Event.ContextEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Event do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic, 3, type: :string
  field :data, 4, type: :string
  field :source, 5, type: :string
  field :userId, 6, type: :string
  field :anonymousId, 7, type: :string
  field :occurredAt, 8, type: :string
  field :context, 9, repeated: true, type: ERWeb.Grpc.Eventrelay.Event.ContextEntry, map: true
  field :offset, 10, type: :int32
  field :errors, 11, repeated: true, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.PublishEventsRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :topic, 1, type: :string
  field :events, 2, repeated: true, type: ERWeb.Grpc.Eventrelay.NewEvent
  field :durable, 3, type: :bool
end

defmodule ERWeb.Grpc.Eventrelay.PublishEventsResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
  field :totalCount, 2, type: :int32
  field :nextOffset, 3, type: :int32
  field :previousOffset, 4, type: :int32
  field :totalBatches, 5, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.PullEventsRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :topic, 1, type: :string
  field :batchSize, 2, type: :int32
  field :offset, 3, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.PullEventsResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
end

defmodule ERWeb.Grpc.Eventrelay.ApiKey do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
  field :key, 2, type: :string
  field :secret, 3, type: :string
  field :status, 4, type: :string
  field :type, 5, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateApiKeyRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :type, 4, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateApiKeyResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :apiKey, 1, type: ERWeb.Grpc.Eventrelay.ApiKey
end

defmodule ERWeb.Grpc.Eventrelay.RevokeApiKeyRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.RevokeApiKeyResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :apiKey, 1, type: ERWeb.Grpc.Eventrelay.ApiKey
end

defmodule ERWeb.Grpc.Eventrelay.AddSubscriptionToApiKeyRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :apiKeyId, 1, type: :string
  field :subscriptionId, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.AddSubscriptionToApiKeyResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :apiKeyId, 1, type: :string
  field :subscriptionId, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionFromApiKeyRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :apiKeyId, 1, type: :string
  field :subscriptionId, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionFromApiKeyResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :apiKeyId, 1, type: :string
  field :subscriptionId, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateJWTRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :expiration, 1, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.CreateJWTResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :jwt, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.EventRelay.Service do
  @moduledoc false
  use GRPC.Service, name: "eventrelay.EventRelay", protoc_gen_elixir_version: "0.11.0"

  rpc :PublishEvents,
      ERWeb.Grpc.Eventrelay.PublishEventsRequest,
      ERWeb.Grpc.Eventrelay.PublishEventsResponse

  rpc :PullEvents,
      ERWeb.Grpc.Eventrelay.PullEventsRequest,
      ERWeb.Grpc.Eventrelay.PullEventsResponse

  rpc :ListTopics,
      ERWeb.Grpc.Eventrelay.ListTopicsRequest,
      ERWeb.Grpc.Eventrelay.ListTopicsResponse

  rpc :CreateTopic,
      ERWeb.Grpc.Eventrelay.CreateTopicRequest,
      ERWeb.Grpc.Eventrelay.CreateTopicResponse

  rpc :DeleteTopic,
      ERWeb.Grpc.Eventrelay.DeleteTopicRequest,
      ERWeb.Grpc.Eventrelay.DeleteTopicResponse

  rpc :ListSubscriptions,
      ERWeb.Grpc.Eventrelay.ListSubscriptionsRequest,
      ERWeb.Grpc.Eventrelay.ListSubscriptionsResponse

  rpc :GetSubscription,
      ERWeb.Grpc.Eventrelay.GetSubscriptionRequest,
      ERWeb.Grpc.Eventrelay.GetSubscriptionResponse

  rpc :CreateSubscription,
      ERWeb.Grpc.Eventrelay.CreateSubscriptionRequest,
      ERWeb.Grpc.Eventrelay.CreateSubscriptionResponse

  rpc :DeleteSubscription,
      ERWeb.Grpc.Eventrelay.DeleteSubscriptionRequest,
      ERWeb.Grpc.Eventrelay.DeleteSubscriptionResponse

  rpc :CreateApiKey,
      ERWeb.Grpc.Eventrelay.CreateApiKeyRequest,
      ERWeb.Grpc.Eventrelay.CreateApiKeyResponse

  rpc :RevokeApiKey,
      ERWeb.Grpc.Eventrelay.RevokeApiKeyRequest,
      ERWeb.Grpc.Eventrelay.RevokeApiKeyResponse

  rpc :AddSubscriptionToApiKey,
      ERWeb.Grpc.Eventrelay.AddSubscriptionToApiKeyRequest,
      ERWeb.Grpc.Eventrelay.AddSubscriptionToApiKeyResponse

  rpc :DeleteSubscriptionFromApiKey,
      ERWeb.Grpc.Eventrelay.DeleteSubscriptionFromApiKeyRequest,
      ERWeb.Grpc.Eventrelay.DeleteSubscriptionFromApiKeyResponse

  rpc :CreateJWT, ERWeb.Grpc.Eventrelay.CreateJWTRequest, ERWeb.Grpc.Eventrelay.CreateJWTResponse
end

defmodule ERWeb.Grpc.Eventrelay.EventRelay.Stub do
  @moduledoc false
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.EventRelay.Service
end