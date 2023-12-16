# EventRelay (Current Status: ALPHA)

[![Elixir CI](https://github.com/eventrelay/eventrelay/actions/workflows/elixir.yml/badge.svg)](https://github.com/eventrelay/eventrelay/actions/workflows/elixir.yml)

EventRelay is a simple to use event storage and streaming platform. 

## 🥅 Goals

- Foster a dynamic and engaged community and ecosystem.
- Deliver an exceptional developer experience.
- Facilitate minimal production administration.

## Give it a Spin 🚀

Checkout [Getting Started](https://github.com/eventrelay/eventrelay/wiki/Getting-Started) to get EventRelay setup locally.

After you have it setup locally take a look at [Up and Running](https://github.com/eventrelay/eventrelay/wiki/Up-and-Running) to publish your first event.


## Projects Using EventRelay 🤝

### Event Sources

[WalEx](https://github.com/cpursley/walex)

Subscribe to Postgres change events and stream them directly into EventRelay via a simple [config](https://github.com/eventrelay).

[Bosun](https://github.com/themusicman/bosun) 

An Elixir-based authorization package that generates an audit log and can optionally transmit it to EventRelay.


## Use Cases ⚡

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

### Webhooks

EventRelay includes built-in webhook support, eliminating the need to concern yourself with implementing retry logic or other complexities associated with sending POST requests.

### Websockets

Whether you're implementing a notification system, a chat application, or simply updating metrics on a dashboard, EventRelay effortlessly manages all aspects of websocket communication for you.

## Web UI
![Events](https://github.com/eventrelay/eventrelay/assets/41780/5aa1f274-f417-41c9-b091-832c194f2267)

## Want to contribute or look at the roadmap?

Checkout the [GitHub Project Board](https://github.com/orgs/eventrelay/projects/1).
