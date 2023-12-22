defmodule ERWeb.WebhookController do
  use ERWeb, :controller

  require Logger

  action_fallback ERWeb.FallbackController

  def ingest(conn, params) do
    ingestor = conn.assigns[:ingestor]

    data = Map.drop(params, ["ingestor_id"])
    topic_name = ingestor.topic_name
    verified = false
    durable = true

    ER.Events.produce_event_for_topic(%{
      name: "webhook.inbound",
      source: ingestor.source,
      data: data,
      durable: durable,
      verified: verified,
      topic_name: topic_name
    })

    conn
    |> put_status(:ok)
    |> text("OK")
  end
end
