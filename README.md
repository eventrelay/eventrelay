# EventRelay

It is not meant to be the fastest or most webscale event streaming system out there. It will never compete with the
likes of Kafka for most throughput or lowest latency. It is meant to be a low maintenance, reliable, and easy to use
event streaming alternative for the rest of us.

To start the server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

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
grpcurl -plaintext -proto event_relay.proto -d '{"name": "users"}' localhost:50051 eventrelay.EventRelay.CreateTopic
```

Publish an event:

```
grpcurl -plaintext -proto event_relay.proto -d '{"topic": "users", "events": [{"name": "user.created", "data": "{\"first_name\": \"Thomas\"}", "source": "grpc", "context": {"ip_address": "127.0.0.1"}}]}' localhost:50051 eventrelay.EventRelay.PublishEvents
```

Create a subscription:
```
grpcurl -plaintext -proto event_relay.proto -d '{"subscription": {"name": "tacos4life", "topicName": "users", "topicIdentifier": "123", "config": {"endpoint_url": "https://example.com/webhooks/users"}, "push": true, "subscriptionType": "websocket"}}' localhost:50051 eventrelay.EventRelay.CreateSubscription
```

```
grpcurl -plaintext -proto event_relay.proto -d '{"subscription": {"name": "tacos4life", "topicName": "users", "config": {}, "push": true, "subscriptionType": "websocket"}}' localhost:50051 eventrelay.EventRelay.CreateSubscription
```

Delete a subscription:

```
grpcurl -plaintext -proto event_relay.proto -d '{"id": "93132ce1-7e76-4439-956b-6001a1d43c32"}' localhost:50051 eventrelay.EventRelay.DeleteSubscription
```

List subscriptions:

```
grpcurl -plaintext -proto event_relay.proto -d '{"page": 1, "pageSize": 100}' localhost:50051 eventrelay.EventRelay.ListSubscriptions
```

## Event

{
  "eventId": "04f7f9b0-5b9b-11eb-9e8b-0f1f9b4f4a9c",
  "name": "user_login",
  "topic": "organization:1234",
  "source": "grpc|websocket",
  "userId": "123",
  "eventOccurredAt": "2020-01-01T00:00:00.000Z"
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

Both are handled using JWTs. EventRelay uses the `HS256` signing algorithm with a shared secret. You can set the shared
secret via the `ER_JWT_SECRET` environment variable. The secret should be strong and at least 32 characters long. 

In the JWT you can set claims for authorization:

- `topics` - which is a comma seperated list of topics the JWT is authorized to use. ex.
    `users:123,visits:123,checkouts:123`


## Delivery Guarantees

For websocket and streaming GRPC API there is a best effort attempt to deliver the event. What this means is EventRelay will
attempt to deliver the event but if there are network issue or a client is not connected at the time the event occurs the event wil notbe received by the client. There is no acknowledgement mechanism or offset tracking via these 2 channels. 

For webhooks any 2xx HTTP response status will be accepted as acknowledgement of receiving the event. Any other HTTP
status will be considered a failure to acknowledge receiving the event and the event will be retried according
to the webhook retry configuration. By default up to 20 attempts will be made before it is marked as undeliverable.
Webhooks are also processed in order per topic per destination so if EventRelay gets something other than a 2xx response
it will pause sending events for that topic/destination to preserve the order.

## Todos

- [x] GRPC API to publish events
- [x] GRPC API to list,create topics
- [ ] GRPC API to create,delete,list subscriptions
- [ ] websocket streaming implementation
- [ ] pull events GRPC API (offset/batch based)
- [ ] add auth
- [ ] add rate limiting
- [ ] webhook implementation
- [ ] index event table properly
- [ ] GRPC streaming implementation


