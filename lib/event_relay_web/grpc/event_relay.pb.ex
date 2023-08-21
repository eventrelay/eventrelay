defmodule ERWeb.Grpc.Eventrelay.CastAs do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :INTEGER, 0
  field :FLOAT, 1
  field :STRING, 2
  field :DATE, 3
  field :DATETIME, 4
end

defmodule ERWeb.Grpc.Eventrelay.MetricType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :SUM, 0
  field :AVG, 1
  field :MIN, 2
  field :MAX, 3
  field :COUNT, 4
end

defmodule ERWeb.Grpc.Eventrelay.ApiKeyType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :PRODUCER, 0
  field :CONSUMER, 1
end

defmodule ERWeb.Grpc.Eventrelay.ApiKeyStatus do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :ACTIVE, 0
  field :REVOKED, 1
end

defmodule ERWeb.Grpc.Eventrelay.Topic do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.ListTopicsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :page, 1, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.ListTopicsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :topics, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.CreateTopicRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :name, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateTopicResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :topic, 1, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :topic, 1, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.NewSubscription.ConfigEntry do
  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.NewSubscription do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :name, 1, type: :string
  field :topic_name, 2, type: :string, json_name: "topicName"
  field :topic_identifier, 3, type: :string, json_name: "topicIdentifier"
  field :push, 4, type: :bool

  field :config, 6,
    repeated: true,
    type: ERWeb.Grpc.Eventrelay.NewSubscription.ConfigEntry,
    map: true

  field :paused, 7, type: :bool
  field :subscription_type, 8, type: :string, json_name: "subscriptionType"
end

defmodule ERWeb.Grpc.Eventrelay.Subscription.ConfigEntry do
  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Subscription do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic_name, 3, type: :string, json_name: "topicName"
  field :topic_identifier, 4, type: :string, json_name: "topicIdentifier"
  field :push, 5, type: :bool

  field :config, 7,
    repeated: true,
    type: ERWeb.Grpc.Eventrelay.Subscription.ConfigEntry,
    map: true

  field :paused, 8, type: :bool
  field :subscription_type, 9, type: :string, json_name: "subscriptionType"
end

defmodule ERWeb.Grpc.Eventrelay.ListSubscriptionsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :page, 1, type: :int32
  field :page_size, 2, type: :int32, json_name: "pageSize"
end

defmodule ERWeb.Grpc.Eventrelay.ListSubscriptionsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :subscriptions, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Subscription
  field :total_count, 2, type: :int32, json_name: "totalCount"
  field :next_page, 3, type: :int32, json_name: "nextPage"
  field :previous_page, 4, type: :int32, json_name: "previousPage"
  field :total_pages, 5, type: :int32, json_name: "totalPages"
end

defmodule ERWeb.Grpc.Eventrelay.GetSubscriptionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetSubscriptionResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.Subscription
end

defmodule ERWeb.Grpc.Eventrelay.CreateSubscriptionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.NewSubscription
end

defmodule ERWeb.Grpc.Eventrelay.CreateSubscriptionResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.Subscription
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :subscription, 1, type: ERWeb.Grpc.Eventrelay.Subscription
end

defmodule ERWeb.Grpc.Eventrelay.NewEvent.ContextEntry do
  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.NewEvent do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :name, 1, type: :string
  field :data, 2, type: :string
  field :source, 3, type: :string
  field :group_key, 4, type: :string, json_name: "groupKey"
  field :reference_key, 5, type: :string, json_name: "referenceKey"
  field :trace_key, 6, type: :string, json_name: "traceKey"
  field :user_id, 7, type: :string, json_name: "userId"
  field :anonymous_id, 8, type: :string, json_name: "anonymousId"
  field :occurred_at, 9, type: :string, json_name: "occurredAt"
  field :context, 10, repeated: true, type: ERWeb.Grpc.Eventrelay.NewEvent.ContextEntry, map: true
end

defmodule ERWeb.Grpc.Eventrelay.Event.ContextEntry do
  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Event do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic, 3, type: :string
  field :data, 4, type: :string
  field :source, 5, type: :string
  field :group_key, 6, type: :string, json_name: "groupKey"
  field :reference_key, 7, type: :string, json_name: "referenceKey"
  field :trace_key, 8, type: :string, json_name: "traceKey"
  field :user_id, 9, type: :string, json_name: "userId"
  field :anonymous_id, 10, type: :string, json_name: "anonymousId"
  field :occurred_at, 11, type: :string, json_name: "occurredAt"
  field :context, 12, repeated: true, type: ERWeb.Grpc.Eventrelay.Event.ContextEntry, map: true
  field :offset, 13, type: :int32
  field :errors, 14, repeated: true, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.PublishEventsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :topic, 1, type: :string
  field :events, 2, repeated: true, type: ERWeb.Grpc.Eventrelay.NewEvent
  field :durable, 3, type: :bool
end

defmodule ERWeb.Grpc.Eventrelay.PublishEventsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
end

defmodule ERWeb.Grpc.Eventrelay.PullEventsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :topic, 1, type: :string
  field :batch_size, 2, type: :int32, json_name: "batchSize"
  field :offset, 3, type: :int32
  field :filters, 4, repeated: true, type: ERWeb.Grpc.Eventrelay.Filter
end

defmodule ERWeb.Grpc.Eventrelay.Filter do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :field, 1, type: :string
  field :comparison, 2, type: :string
  field :value, 3, type: :string
  field :field_path, 4, type: :string, json_name: "fieldPath"
  field :cast_as, 5, type: ERWeb.Grpc.Eventrelay.CastAs, json_name: "castAs", enum: true
end

defmodule ERWeb.Grpc.Eventrelay.PullEventsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
  field :total_count, 2, type: :int32, json_name: "totalCount"
  field :next_offset, 3, type: :int32, json_name: "nextOffset"
  field :previous_offset, 4, type: :int32, json_name: "previousOffset"
  field :total_batches, 5, type: :int32, json_name: "totalBatches"
end

defmodule ERWeb.Grpc.Eventrelay.NewMetric do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :name, 1, type: :string
  field :topic_name, 2, type: :string, json_name: "topicName"
  field :topic_identifier, 3, type: :string, json_name: "topicIdentifier"
  field :field_path, 4, type: :string, json_name: "fieldPath"
  field :type, 5, type: ERWeb.Grpc.Eventrelay.MetricType, enum: true
  field :filters, 6, repeated: true, type: ERWeb.Grpc.Eventrelay.Filter
end

defmodule ERWeb.Grpc.Eventrelay.Metric do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic_name, 3, type: :string, json_name: "topicName"
  field :topic_identifier, 4, type: :string, json_name: "topicIdentifier"
  field :field_path, 5, type: :string, json_name: "fieldPath"
  field :type, 6, type: ERWeb.Grpc.Eventrelay.MetricType, enum: true
  field :filters, 7, repeated: true, type: ERWeb.Grpc.Eventrelay.Filter
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricValueRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricValueResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :value, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.ListMetricsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :topic, 1, type: :string
  field :page, 2, type: :int32
  field :page_size, 3, type: :int32, json_name: "pageSize"
  field :filters, 4, repeated: true, type: ERWeb.Grpc.Eventrelay.Filter
end

defmodule ERWeb.Grpc.Eventrelay.ListMetricsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :metrics, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Metric
  field :total_count, 2, type: :int32, json_name: "totalCount"
  field :next_page, 3, type: :int32, json_name: "nextPage"
  field :previous_page, 4, type: :int32, json_name: "previousPage"
  field :total_pages, 5, type: :int32, json_name: "totalPages"
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.Metric
end

defmodule ERWeb.Grpc.Eventrelay.CreateMetricRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.NewMetric
end

defmodule ERWeb.Grpc.Eventrelay.CreateMetricResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.Metric
end

defmodule ERWeb.Grpc.Eventrelay.DeleteMetricRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteMetricResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.Metric
end

defmodule ERWeb.Grpc.Eventrelay.ApiKey do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :key, 2, type: :string
  field :secret, 3, type: :string
  field :status, 4, type: ERWeb.Grpc.Eventrelay.ApiKeyStatus, enum: true
  field :type, 5, type: ERWeb.Grpc.Eventrelay.ApiKeyType, enum: true
end

defmodule ERWeb.Grpc.Eventrelay.CreateApiKeyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :type, 4, type: ERWeb.Grpc.Eventrelay.ApiKeyType, enum: true
end

defmodule ERWeb.Grpc.Eventrelay.CreateApiKeyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :api_key, 1, type: ERWeb.Grpc.Eventrelay.ApiKey, json_name: "apiKey"
end

defmodule ERWeb.Grpc.Eventrelay.RevokeApiKeyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.RevokeApiKeyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :api_key, 1, type: ERWeb.Grpc.Eventrelay.ApiKey, json_name: "apiKey"
end

defmodule ERWeb.Grpc.Eventrelay.AddSubscriptionsToApiKeyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :subscription_ids, 2, repeated: true, type: :string, json_name: "subscriptionIds"
end

defmodule ERWeb.Grpc.Eventrelay.AddSubscriptionsToApiKeyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :subscription_ids, 2, repeated: true, type: :string, json_name: "subscriptionIds"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionsFromApiKeyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :subscription_ids, 2, repeated: true, type: :string, json_name: "subscriptionIds"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteSubscriptionsFromApiKeyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :subscription_ids, 2, repeated: true, type: :string, json_name: "subscriptionIds"
end

defmodule ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.CreateJWTRequest do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :expiration, 1, type: :int64
end

defmodule ERWeb.Grpc.Eventrelay.CreateJWTResponse do
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :jwt, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.EventRelay.Service do
  use GRPC.Service, name: "eventrelay.EventRelay", protoc_gen_elixir_version: "0.12.0"

  rpc(
    :PublishEvents,
    ERWeb.Grpc.Eventrelay.PublishEventsRequest,
    ERWeb.Grpc.Eventrelay.PublishEventsResponse
  )

  rpc(
    :PullEvents,
    ERWeb.Grpc.Eventrelay.PullEventsRequest,
    ERWeb.Grpc.Eventrelay.PullEventsResponse
  )

  rpc(
    :ListMetrics,
    ERWeb.Grpc.Eventrelay.ListMetricsRequest,
    ERWeb.Grpc.Eventrelay.ListMetricsResponse
  )

  rpc(:GetMetric, ERWeb.Grpc.Eventrelay.GetMetricRequest, ERWeb.Grpc.Eventrelay.GetMetricResponse)

  rpc(
    :CreateMetric,
    ERWeb.Grpc.Eventrelay.CreateMetricRequest,
    ERWeb.Grpc.Eventrelay.CreateMetricResponse
  )

  rpc(
    :DeleteMetric,
    ERWeb.Grpc.Eventrelay.DeleteMetricRequest,
    ERWeb.Grpc.Eventrelay.DeleteMetricResponse
  )

  rpc(
    :GetMetricValue,
    ERWeb.Grpc.Eventrelay.GetMetricValueRequest,
    ERWeb.Grpc.Eventrelay.GetMetricValueResponse
  )

  rpc(
    :ListTopics,
    ERWeb.Grpc.Eventrelay.ListTopicsRequest,
    ERWeb.Grpc.Eventrelay.ListTopicsResponse
  )

  rpc(
    :CreateTopic,
    ERWeb.Grpc.Eventrelay.CreateTopicRequest,
    ERWeb.Grpc.Eventrelay.CreateTopicResponse
  )

  rpc(
    :DeleteTopic,
    ERWeb.Grpc.Eventrelay.DeleteTopicRequest,
    ERWeb.Grpc.Eventrelay.DeleteTopicResponse
  )

  rpc(
    :ListSubscriptions,
    ERWeb.Grpc.Eventrelay.ListSubscriptionsRequest,
    ERWeb.Grpc.Eventrelay.ListSubscriptionsResponse
  )

  rpc(
    :GetSubscription,
    ERWeb.Grpc.Eventrelay.GetSubscriptionRequest,
    ERWeb.Grpc.Eventrelay.GetSubscriptionResponse
  )

  rpc(
    :CreateSubscription,
    ERWeb.Grpc.Eventrelay.CreateSubscriptionRequest,
    ERWeb.Grpc.Eventrelay.CreateSubscriptionResponse
  )

  rpc(
    :DeleteSubscription,
    ERWeb.Grpc.Eventrelay.DeleteSubscriptionRequest,
    ERWeb.Grpc.Eventrelay.DeleteSubscriptionResponse
  )

  rpc(
    :CreateApiKey,
    ERWeb.Grpc.Eventrelay.CreateApiKeyRequest,
    ERWeb.Grpc.Eventrelay.CreateApiKeyResponse
  )

  rpc(
    :RevokeApiKey,
    ERWeb.Grpc.Eventrelay.RevokeApiKeyRequest,
    ERWeb.Grpc.Eventrelay.RevokeApiKeyResponse
  )

  rpc(
    :AddSubscriptionsToApiKey,
    ERWeb.Grpc.Eventrelay.AddSubscriptionsToApiKeyRequest,
    ERWeb.Grpc.Eventrelay.AddSubscriptionsToApiKeyResponse
  )

  rpc(
    :DeleteSubscriptionsFromApiKey,
    ERWeb.Grpc.Eventrelay.DeleteSubscriptionsFromApiKeyRequest,
    ERWeb.Grpc.Eventrelay.DeleteSubscriptionsFromApiKeyResponse
  )

  rpc(
    :AddTopicsToApiKey,
    ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyRequest,
    ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyResponse
  )

  rpc(
    :DeleteTopicsFromApiKey,
    ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyRequest,
    ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyResponse
  )

  rpc(:CreateJWT, ERWeb.Grpc.Eventrelay.CreateJWTRequest, ERWeb.Grpc.Eventrelay.CreateJWTResponse)
end

defmodule ERWeb.Grpc.Eventrelay.EventRelay.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.EventRelay.Service
end
