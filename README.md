# EventRelay

It is not meant to be the fastest or most webscale event streaming/storage system out there. It will never compete with the
likes of Kafka for most throughput or lowest latency. It is meant to be a low maintenance, reliable, and easy to use
event streaming/storage alternative for the rest of us.

To start the server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:9000`](http://localhost:9000) from your browser.

## GRPC

Command to produce Elixir GRPC autogenerated code: `protoc --elixir_out=plugins=grpc:./lib/event_relay_web/grpc
--elixir_opt=include_docs=true --elixir_opt=package_prefix=ERWeb.Grpc  *.proto`

Get a list of topics:

```
grpcurl -plaintext -proto event_relay.proto localhost:50051 eventrelay.EventRelay.ListTopics
```

Response:

```
{
  "topics": [
    {
      "id": "09d5e848-27ca-4fbc-83e5-d1b9356bb764",
      "name": "default"
    }
  ]
}
```

Create a topic:

```
grpcurl -plaintext -proto event_relay.proto -d '{"name": "metrics"}' localhost:50051 eventrelay.EventRelay.CreateTopic
```

Delete a topic:

```
grpcurl -plaintext -proto event_relay.proto -d '{"id": ""}' localhost:50051 eventrelay.EventRelay.DeleteTopic
```

Publish an event:

```
grpcurl -plaintext -proto event_relay.proto -d '{"topic": "users", "events": [{"name": "user.created", "data": "{\"first_name\": \"Thomas\"}", "source": "grpc", "context": {"ip_address": "127.0.0.1"}}]}' localhost:50051 eventrelay.EventRelay.PublishEvents
```

Load test the publish event:

```
ghz --rps 10000 --total 20000 --insecure --proto event_relay.proto --call eventrelay.EventRelay.PublishEvents -d '{"topic": "users", "events": [{"name": "user.created", "data": "{\"first_name\": \"Thomas\"}", "source": "grpc", "context": {"ip_address": "127.0.0.1"}}]}'  localhost:50051
```

Publish an event without a topic to trigger dead letter:

```
grpcurl -plaintext -proto event_relay.proto -d '{"durable": true, "events": [{"name": "user.updated2", "data": "{\"first_name\": \"Bob\"}", "source": "grpc", "group_key": "testgroup", "reference_key": "testref", "trace_key": "testtrace", "context": {"ip_address": "127.0.0.1"}}]}' localhost:50051 eventrelay.EventRelay.PublishEvents
```

Pull Events:

```
grpcurl -plaintext -proto event_relay.proto -d '{"topic": "users", "offset": 0, "batch_size": 10}' localhost:50051 eventrelay.EventRelay.PullEvents
```

Create a subscription:

```
grpcurl -plaintext -proto event_relay.proto -d '{"subscription": {"name": "events4life", "topic_name": "users", "topic_identifier": "123", "config": {"endpoint_url": "https://example.com/webhooks/users"}, "push": true, "subscription_type": "websocket"}}' localhost:50051 eventrelay.EventRelay.CreateSubscription
```

```
grpcurl -plaintext -proto event_relay.proto -d '{"subscription": {"name": "events4life", "topic_name": "users", "config": {}, "push": true, "subscription_type": "websocket"}}' localhost:50051 eventrelay.EventRelay.CreateSubscription
```

List Subscriptions (w/ auth):

```
grpcurl -plaintext -proto event_relay.proto -d '{"page": 1, "pageSize": 100}' --rpc-header "Authorization: Bearer VWgwZFVZVVZDUnp4RjE1TDZqV21DWlQyMl9wVnBmZkZkb190ckotXzhWOjY4RmdvV2R3WGRqY3NPRnNWTGw2LUgtZzlUaW45SVRuejNVdWVlWXRtOVp0QVBZN3picVhETWE4NFUxWlVsQkg=" localhost:50051 eventrelay.EventRelay.ListSubscriptions
```

Create webhook subscription:

```
grpcurl -plaintext -proto event_relay.proto -d '{"subscription": {"name": "events4life_webhook", "topic_name": "users", "config": {"endpoint_url": "http://localhost:5006/webhook"}, "push": true, "subscription_type": "webhook"}}' localhost:50051 eventrelay.EventRelay.CreateSubscription
```

Delete a subscription:

```
grpcurl -plaintext -proto event_relay.proto -d '{"id": "93132ce1-7e76-4439-956b-6001a1d43c32"}' localhost:50051 eventrelay.EventRelay.DeleteSubscription
```

List subscriptions:

```
grpcurl -plaintext -proto event_relay.proto -d '{"page": 1, "page_size": 100}' localhost:50051 eventrelay.EventRelay.ListSubscriptions
```

Create ApiKey:

```
grpcurl -plaintext -proto event_relay.proto -d '{"type": "consumer"}' localhost:50051
eventrelay.EventRelay.CreateApiKey
```

## Event

{
"id": "04f7f9b0-5b9b-11eb-9e8b-0f1f9b4f4a9c",
"name": "user_login",
"topic": "organization:1234",
"source": "grpc|websocket",
"user_id": "123",
"anonymous_id": "123",
"occurred_at": "2020-01-01T00:00:00.000Z"
"context": {
},
"data": {
"email": "thomas@example.com",
},
}

Events are stored in a per topic table. If the event topic name is `users` then the table that stores the events will be
`users_events`. This is done to shard the events over multiple tables instead of having one massive events table.

## Topic

A topic is like a bucket that is used to organize your events. It is composed of 2 parts:

Ex. `users:123`

The first part `users` is the topic name (character limit of 50) and the second part `123` is the topic id - which is optional. The topic id if provided allows you to scope access to the topic. See the Authentication and Authentication section.

More examples of valid topics:

Ex.

- `form_submissions`
- `signups:987`

A topic name can only be a max of 50 characters.

## Authentication and Authorization

There are two types of API keys: producer and consumer.

A producer API key is allowed to interact with the all of the GRPC API and

## Delivery Guarantees

For websocket and streaming GRPC API there is a best effort attempt to deliver the event. What this means is EventRelay will
attempt to deliver the event but if there are network issue or a client is not connected at the time the event occurs the event wil notbe received by the client. There is no acknowledgement mechanism or offset tracking via these 2 channels.

For webhooks any 2xx HTTP response status will be accepted as acknowledgement of receiving the event. Any other HTTP
status will be considered a failure to acknowledge receiving the event and the event will be retried according
to the webhook retry configuration. By default up to 20 attempts will be made before it is marked as undeliverable.
~~Webhooks are also processed in order per topic per destination so if EventRelay gets something other than a 2xx response
it will pause sending events for that topic/destination to preserve the order.~~

## Todos

- [x] GRPC API to publish events
- [x] GRPC API to list,create,delete topics
- [x] GRPC API to create,delete,list subscriptions
- [x] GRPC API to create,revoke api keys
- [x] GRPC API to create JWT for an api key
- [x] websocket streaming implementation
- [x] pull events GRPC API (offset/batch based)
- [x] webhook implementation
- [x] add auth
- [x] add rate limiting
- [x] add auth to websocket
- [x] websocket publish events (code commented out until producer topic authorization figured out)
- [x] non-durable events
- [x] figure out producer topic authorization
- [x] test not passing topic when publishing events
- [x] UI to manage topics
- [x] UI to view events
- [x] UI to API Keys
- [x] Write Google PubSub ingestor
- [x] Ability to apply lua scripts to ingested events
- [x] Metrics
- [ ] Write tests!!!!
- [x] Broadcast metrics updates via subscriptions and internal pubsub
- [ ] Refactor EventFilter to Filter
- [ ] Ability to forward an event to another topic and transform the event with a lua script
- [ ] add histogram type metric
- [ ] make sure subscription and delivery servers restart properly
- [ ] UI for managing Ingestors/Transformers
- [ ] UI to tail events
- [ ] UI to manage subscriptions
- [ ] UI to view deliveries
- [ ] add subscription/delivery server crash state reloading from redis
- [ ] Improve docs about Google PubSub ingestor
- [ ] switch to Nebulex redis adapter
- [ ] Write S3 subscription
- [ ] Write S3 ingestor
- [ ] index event table properly
- [ ] add documentation to event_relay.proto file
- [ ] generate HTML docs from event_relay.proto file
- [ ] add pagination to list topics
- [ ] test all the authorization policies
- [ ] Standardize logging formatting
- [ ] Implement json logger
- [ ] add rate limiting for webhooks
- [ ] GRPC streaming implementation
- [ ] UI to manage users
- [ ] Test various scenarios of creating and droping topics
