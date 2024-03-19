defmodule ERWeb.Grpc.Eventrelay.CastAs do
  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :STRING, 0
  field :INTEGER, 1
  field :FLOAT, 2
  field :DATE, 3
  field :DATETIME, 4
  field :BOOLEAN, 5
end

defmodule ERWeb.Grpc.Eventrelay.MetricType do
  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :SUM, 0
  field :AVG, 1
  field :MIN, 2
  field :MAX, 3
  field :COUNT, 4
end

defmodule ERWeb.Grpc.Eventrelay.ApiKeyType do
  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :PRODUCER, 0
  field :CONSUMER, 1
end

defmodule ERWeb.Grpc.Eventrelay.ApiKeyStatus do
  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :ACTIVE, 0
  field :REVOKED, 1
end

defmodule ERWeb.Grpc.Eventrelay.Topic do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :group_key, 3, type: :string, json_name: "groupKey"
end

defmodule ERWeb.Grpc.Eventrelay.ListTopicsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :page, 1, type: :int32
end

defmodule ERWeb.Grpc.Eventrelay.ListTopicsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :topics, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.CreateTopicRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :name, 1, type: :string
  field :group_key, 2, type: :string, json_name: "groupKey"
end

defmodule ERWeb.Grpc.Eventrelay.CreateTopicResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :topic, 1, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :topic, 1, type: ERWeb.Grpc.Eventrelay.Topic
end

defmodule ERWeb.Grpc.Eventrelay.Destination.ConfigEntry do
  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Destination do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic_name, 3, type: :string, json_name: "topicName"
  field :topic_identifier, 4, type: :string, json_name: "topicIdentifier"
  field :config, 5, repeated: true, type: ERWeb.Grpc.Eventrelay.Destination.ConfigEntry, map: true
  field :destination_type, 6, type: :string, json_name: "destinationType"
  field :group_key, 7, type: :string, json_name: "groupKey"
end

defmodule ERWeb.Grpc.Eventrelay.ListDestinationsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :page, 1, type: :int32
  field :page_size, 2, type: :int32, json_name: "pageSize"
end

defmodule ERWeb.Grpc.Eventrelay.ListDestinationsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :destinations, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Destination
  field :total_count, 2, type: :int32, json_name: "totalCount"
  field :next_page, 3, type: :int32, json_name: "nextPage"
  field :previous_page, 4, type: :int32, json_name: "previousPage"
  field :total_pages, 5, type: :int32, json_name: "totalPages"
end

defmodule ERWeb.Grpc.Eventrelay.GetDestinationRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetDestinationResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :destination, 1, type: ERWeb.Grpc.Eventrelay.Destination
end

defmodule ERWeb.Grpc.Eventrelay.CreateDestinationRequest.ConfigEntry do
  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateDestinationRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :name, 1, type: :string
  field :topic_name, 2, type: :string, json_name: "topicName"
  field :topic_identifier, 3, type: :string, json_name: "topicIdentifier"

  field :config, 4,
    repeated: true,
    type: ERWeb.Grpc.Eventrelay.CreateDestinationRequest.ConfigEntry,
    map: true

  field :paused, 5, type: :bool
  field :destination_type, 6, type: :string, json_name: "destinationType"
  field :group_key, 7, type: :string, json_name: "groupKey"
end

defmodule ERWeb.Grpc.Eventrelay.CreateDestinationResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :destination, 1, type: ERWeb.Grpc.Eventrelay.Destination
end

defmodule ERWeb.Grpc.Eventrelay.DeleteDestinationRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteDestinationResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :destination, 1, type: ERWeb.Grpc.Eventrelay.Destination
end

defmodule ERWeb.Grpc.Eventrelay.NewEvent.ContextEntry do
  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.NewEvent do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :name, 1, type: :string
  field :data, 2, type: :string
  field :source, 3, type: :string
  field :group_key, 4, type: :string, json_name: "groupKey"
  field :reference_key, 5, type: :string, json_name: "referenceKey"
  field :trace_key, 6, type: :string, json_name: "traceKey"
  field :user_key, 7, type: :string, json_name: "userKey"
  field :anonymous_key, 8, type: :string, json_name: "anonymousKey"
  field :occurred_at, 9, type: :string, json_name: "occurredAt"
  field :context, 10, repeated: true, type: ERWeb.Grpc.Eventrelay.NewEvent.ContextEntry, map: true
  field :data_schema, 11, type: :string, json_name: "dataSchema"
  field :prev_id, 12, type: :string, json_name: "prevId"
  field :available_at, 13, type: :string, json_name: "availableAt"
end

defmodule ERWeb.Grpc.Eventrelay.Event.ContextEntry do
  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Event do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic, 3, type: :string
  field :data, 4, type: :string
  field :source, 5, type: :string
  field :group_key, 6, type: :string, json_name: "groupKey"
  field :reference_key, 7, type: :string, json_name: "referenceKey"
  field :trace_key, 8, type: :string, json_name: "traceKey"
  field :user_key, 9, type: :string, json_name: "userKey"
  field :anonymous_key, 10, type: :string, json_name: "anonymousKey"
  field :occurred_at, 11, type: :string, json_name: "occurredAt"
  field :context, 12, repeated: true, type: ERWeb.Grpc.Eventrelay.Event.ContextEntry, map: true
  field :offset, 13, type: :int32
  field :errors, 14, repeated: true, type: :string
  field :data_schema, 15, type: :string, json_name: "dataSchema"
  field :prev_id, 16, type: :string, json_name: "prevId"
  field :available_at, 17, type: :string, json_name: "availableAt"
end

defmodule ERWeb.Grpc.Eventrelay.PublishEventsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :topic, 1, type: :string
  field :events, 2, repeated: true, type: ERWeb.Grpc.Eventrelay.NewEvent
end

defmodule ERWeb.Grpc.Eventrelay.PublishEventsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
end

defmodule ERWeb.Grpc.Eventrelay.PullEventsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :topic, 1, type: :string
  field :batch_size, 2, type: :int32, json_name: "batchSize"
  field :offset, 3, type: :int32
  field :query, 4, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.PullEventsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
  field :total_count, 2, type: :int32, json_name: "totalCount"
  field :next_offset, 3, type: :int32, json_name: "nextOffset"
  field :previous_offset, 4, type: :int32, json_name: "previousOffset"
  field :total_batches, 5, type: :int32, json_name: "totalBatches"
end

defmodule ERWeb.Grpc.Eventrelay.PullQueuedEventsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :destination_id, 1, type: :string, json_name: "destinationId"
  field :batch_size, 2, type: :int32, json_name: "batchSize"
end

defmodule ERWeb.Grpc.Eventrelay.PullQueuedEventsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
end

defmodule ERWeb.Grpc.Eventrelay.UnLockQueuedEventsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :destination_id, 1, type: :string, json_name: "destinationId"
  field :event_ids, 2, repeated: true, type: :string, json_name: "eventIds"
end

defmodule ERWeb.Grpc.Eventrelay.UnLockQueuedEventsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :events, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Event
end

defmodule ERWeb.Grpc.Eventrelay.Filter do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :field, 1, type: :string
  field :comparison, 2, type: :string
  field :value, 3, type: :string
  field :field_path, 4, type: :string, json_name: "fieldPath"
  field :cast_as, 5, type: ERWeb.Grpc.Eventrelay.CastAs, json_name: "castAs", enum: true
end

defmodule ERWeb.Grpc.Eventrelay.Metric do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :topic_name, 3, type: :string, json_name: "topicName"
  field :topic_identifier, 4, type: :string, json_name: "topicIdentifier"
  field :field_path, 5, type: :string, json_name: "fieldPath"
  field :type, 6, type: ERWeb.Grpc.Eventrelay.MetricType, enum: true
  field :query, 7, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricValueRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricValueResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :value, 1, type: :double
end

defmodule ERWeb.Grpc.Eventrelay.ListMetricsRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :topic, 1, type: :string
  field :page, 2, type: :int32
  field :page_size, 3, type: :int32, json_name: "pageSize"
  field :query, 4, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.ListMetricsResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :metrics, 1, repeated: true, type: ERWeb.Grpc.Eventrelay.Metric
  field :total_count, 2, type: :int32, json_name: "totalCount"
  field :next_page, 3, type: :int32, json_name: "nextPage"
  field :previous_page, 4, type: :int32, json_name: "previousPage"
  field :total_pages, 5, type: :int32, json_name: "totalPages"
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.GetMetricResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.Metric
end

defmodule ERWeb.Grpc.Eventrelay.CreateMetricRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :name, 1, type: :string
  field :topic_name, 2, type: :string, json_name: "topicName"
  field :topic_identifier, 3, type: :string, json_name: "topicIdentifier"
  field :field_path, 4, type: :string, json_name: "fieldPath"
  field :type, 5, type: ERWeb.Grpc.Eventrelay.MetricType, enum: true
  field :query, 6, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.CreateMetricResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.Metric
end

defmodule ERWeb.Grpc.Eventrelay.DeleteMetricRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.DeleteMetricResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :metric, 1, type: ERWeb.Grpc.Eventrelay.Metric
end

defmodule ERWeb.Grpc.Eventrelay.ApiKey do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :key, 3, type: :string
  field :secret, 4, type: :string
  field :status, 5, type: ERWeb.Grpc.Eventrelay.ApiKeyStatus, enum: true
  field :type, 6, type: ERWeb.Grpc.Eventrelay.ApiKeyType, enum: true
  field :group_key, 7, type: :string, json_name: "groupKey"
  field :tls_hostname, 8, type: :string, json_name: "tlsHostname"
end

defmodule ERWeb.Grpc.Eventrelay.CreateApiKeyRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :type, 1, type: ERWeb.Grpc.Eventrelay.ApiKeyType, enum: true
  field :name, 2, type: :string
  field :group_key, 3, type: :string, json_name: "groupKey"
  field :tls_hostname, 4, type: :string, json_name: "tlsHostname"
end

defmodule ERWeb.Grpc.Eventrelay.CreateApiKeyResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :api_key, 1, type: ERWeb.Grpc.Eventrelay.ApiKey, json_name: "apiKey"
end

defmodule ERWeb.Grpc.Eventrelay.RevokeApiKeyRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.RevokeApiKeyResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :api_key, 1, type: ERWeb.Grpc.Eventrelay.ApiKey, json_name: "apiKey"
end

defmodule ERWeb.Grpc.Eventrelay.AddDestinationsToApiKeyRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :destination_ids, 2, repeated: true, type: :string, json_name: "destinationIds"
end

defmodule ERWeb.Grpc.Eventrelay.AddDestinationsToApiKeyResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :destination_ids, 2, repeated: true, type: :string, json_name: "destinationIds"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteDestinationsFromApiKeyRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :destination_ids, 2, repeated: true, type: :string, json_name: "destinationIds"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteDestinationsFromApiKeyResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :destination_ids, 2, repeated: true, type: :string, json_name: "destinationIds"
end

defmodule ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :topic_names, 2, repeated: true, type: :string, json_name: "topicNames"
end

defmodule ERWeb.Grpc.Eventrelay.CreateJWTRequest do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :expiration, 1, type: :int64
end

defmodule ERWeb.Grpc.Eventrelay.CreateJWTResponse do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :jwt, 1, type: :string
end

defmodule ERWeb.Grpc.Eventrelay.Events.Service do
  use GRPC.Service, name: "eventrelay.Events", protoc_gen_elixir_version: "0.12.0"

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
    :PullQueuedEvents,
    ERWeb.Grpc.Eventrelay.PullQueuedEventsRequest,
    ERWeb.Grpc.Eventrelay.PullQueuedEventsResponse
  )

  rpc(
    :UnLockQueuedEvents,
    ERWeb.Grpc.Eventrelay.UnLockQueuedEventsRequest,
    ERWeb.Grpc.Eventrelay.UnLockQueuedEventsResponse
  )
end

defmodule ERWeb.Grpc.Eventrelay.Events.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.Events.Service
end

defmodule ERWeb.Grpc.Eventrelay.Metrics.Service do
  use GRPC.Service, name: "eventrelay.Metrics", protoc_gen_elixir_version: "0.12.0"

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
end

defmodule ERWeb.Grpc.Eventrelay.Metrics.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.Metrics.Service
end

defmodule ERWeb.Grpc.Eventrelay.Topics.Service do
  use GRPC.Service, name: "eventrelay.Topics", protoc_gen_elixir_version: "0.12.0"

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
end

defmodule ERWeb.Grpc.Eventrelay.Topics.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.Topics.Service
end

defmodule ERWeb.Grpc.Eventrelay.Destinations.Service do
  use GRPC.Service, name: "eventrelay.Destinations", protoc_gen_elixir_version: "0.12.0"

  rpc(
    :ListDestinations,
    ERWeb.Grpc.Eventrelay.ListDestinationsRequest,
    ERWeb.Grpc.Eventrelay.ListDestinationsResponse
  )

  rpc(
    :GetDestination,
    ERWeb.Grpc.Eventrelay.GetDestinationRequest,
    ERWeb.Grpc.Eventrelay.GetDestinationResponse
  )

  rpc(
    :CreateDestination,
    ERWeb.Grpc.Eventrelay.CreateDestinationRequest,
    ERWeb.Grpc.Eventrelay.CreateDestinationResponse
  )

  rpc(
    :DeleteDestination,
    ERWeb.Grpc.Eventrelay.DeleteDestinationRequest,
    ERWeb.Grpc.Eventrelay.DeleteDestinationResponse
  )
end

defmodule ERWeb.Grpc.Eventrelay.Destinations.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.Destinations.Service
end

defmodule ERWeb.Grpc.Eventrelay.ApiKeys.Service do
  use GRPC.Service, name: "eventrelay.ApiKeys", protoc_gen_elixir_version: "0.12.0"

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
    :AddDestinationsToApiKey,
    ERWeb.Grpc.Eventrelay.AddDestinationsToApiKeyRequest,
    ERWeb.Grpc.Eventrelay.AddDestinationsToApiKeyResponse
  )

  rpc(
    :DeleteDestinationsFromApiKey,
    ERWeb.Grpc.Eventrelay.DeleteDestinationsFromApiKeyRequest,
    ERWeb.Grpc.Eventrelay.DeleteDestinationsFromApiKeyResponse
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
end

defmodule ERWeb.Grpc.Eventrelay.ApiKeys.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.ApiKeys.Service
end

defmodule ERWeb.Grpc.Eventrelay.JWT.Service do
  use GRPC.Service, name: "eventrelay.JWT", protoc_gen_elixir_version: "0.12.0"

  rpc(:CreateJWT, ERWeb.Grpc.Eventrelay.CreateJWTRequest, ERWeb.Grpc.Eventrelay.CreateJWTResponse)
end

defmodule ERWeb.Grpc.Eventrelay.JWT.Stub do
  use GRPC.Stub, service: ERWeb.Grpc.Eventrelay.JWT.Service
end
