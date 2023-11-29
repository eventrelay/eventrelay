# EventRelay (Current Status: ALPHA)

[![Elixir CI](https://github.com/eventrelay/eventrelay/actions/workflows/elixir.yml/badge.svg)](https://github.com/eventrelay/eventrelay/actions/workflows/elixir.yml)

## Objectives

- Foster a dynamic and engaged community.
- Deliver an exceptional developer experience.
- Facilitate minimal production administration.

## Getting Started

See the [wiki](https://github.com/eventrelay/eventrelay/wiki/Getting-Started)

## Use Cases

### Event Streaming

EventRelay allows your applications to both publish and consume events through a GRPC API. It employs a pull-based approach to event streaming, akin to projects like Kafka.

#### Worker Queues

Utilize deliver once events to create worker queues via the GRPC API

### Debug Log

Integrate EventRelay seamlessly into your debugging process by sending events to the same locations where you would typically log debug information. This enables you to easily filter and search events, aiding in the resolution of issues within your application.

### Metrics & Analytics

Effortlessly send events to EventRelay and define your desired metrics.

### Customer Data Platform

Collect first party data and make data driven decisions.

### Audit Log

Leverage EventRelay to record events every time you need to track user actions on specific resources within your system.

Example:

[Bosun](https://github.com/themusicman/bosun) is an Elixir-based authorization package that generates an audit log and can optionally transmit it to EventRelay.

### Webhooks

EventRelay includes built-in webhook support, eliminating the need to concern yourself with implementing retry logic or other complexities associated with sending POST requests.

### Websockets

Whether you're implementing a notification system, a chat application, or simply updating metrics on a dashboard, EventRelay effortlessly manages all aspects of websocket communication for you.


## Web UI
![Events](https://github.com/eventrelay/eventrelay/assets/41780/5aa1f274-f417-41c9-b091-832c194f2267)



## GRPC API

See the [wiki](https://github.com/eventrelay/eventrelay/wiki/GRPC) for more about the GRPC API.


## Core Concepts

### Events

Events are stored in a per topic table in the Postgres database. EventRelay at its core is about moving events from one place to another. Whether that is from the API to storage in the database in the case of durable events, from the API to a websocket consumer for durable and non-durable events, or from a source via an ingestor to a consumer via the API. Events are the foundational concept in EventRealy.

Read more about [events](https://github.com/eventrelay/eventrelay/wiki/Events)

### Topics

A topic is like a bucket that is used to organize your events. It is composed of 2 parts:

Ex. `users:123`

The first part `users` is the topic name (character limit of 50) and the second part `123` is the topic id - which is optional. The topic id if provided allows you to scope access to the topic. 

More examples of valid topics:

Ex.

- `form_submissions`
- `signups:987`

A topic name can only be a max of 50 characters.

Read more about [topics](https://github.com/eventrelay/eventrelay/wiki/Topics)

### Subscriptions

In EventRelay subscriptions define who and how events can be consumed by external clients. There are a few different types of subscriptions: API, webhook, websocket, and S3.

Read more about [subscriptions](https://github.com/eventrelay/eventrelay/wiki/Subscriptions)

### Metrics

Metrics are ways of deriving aggregate data about the events that are stored in EventRelay.

Read more about [metrics](https://github.com/eventrelay/eventrelay/wiki/Metrics)

### API Keys

API Keys control access to the various APIs that clients can use to interact with EventRelay.

**APIs**

- GRPC API (main)
- REST API 
    - only supports publishing events
- Websockets 
    - only supports publishing events and consuming events 
    - uses JWT based authentication and authorization
    - an API key can be used to [generate a JWT token](https://github.com/eventrelay/eventrelay/wiki/GRPC#create-jwt-token)
    
Read more about [authentication and authorization](https://github.com/eventrelay/eventrelay/wiki/Authentication-and-Authroization)


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
- [x] Write Google PubSub ingestor
- [x] Ability to apply lua scripts to ingested events
- [x] Metrics
- [x] Broadcast metrics updates via subscriptions and internal pubsub
- [x] Refactor EventFilter to Filter
- [x] Add cast_as to event filter form
- [x] Add occurred_at to field list with > and <
- [x] Implement basic publish events for JSON API

See [GitHub Project](https://github.com/orgs/eventrelay/projects/1) moving forward.
