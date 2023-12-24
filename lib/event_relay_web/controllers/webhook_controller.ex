defmodule ERWeb.WebhookController do
  use ERWeb, :controller

  require Logger
  alias Flamel.Context

  action_fallback ERWeb.FallbackController

  def ingest(conn, params) do
    source = conn.assigns[:source]

    data = Map.drop(params, ["source_id"])
    topic_name = source.topic_name
    verified = false
    durable = true

    Context.new(%{
      event: %{
        name: "webhook.inbound",
        source: source.source,
        data: data,
        durable: durable,
        verified: verified,
        topic_name: topic_name
      }
    })
    |> check_rate_limit()
    |> produce_event()
    |> log()

    conn
    |> put_status(:ok)
    |> text("OK")
  end

  defp check_rate_limit(ctx) do
    case ERWeb.RateLimiter.check_rate("publish_events", durable: true) do
      {:allow, _count} ->
        ctx

      {:deny, method, time_frame, max_req} ->
        Context.halt!(
          ctx,
          "Rate limit exceeded for #{method} at #{max_req} requests per #{time_frame / 1000} second(s)"
        )
    end
  end

  defp produce_event(%Context{halt: true} = ctx) do
    ctx
  end

  defp produce_event(ctx) do
    case ER.Events.produce_event_for_topic(ctx.assigns[:event]) do
      {:ok, event} -> Context.assign(ctx, :event, event)
      {:error, errors} -> Context.halt!(ctx, "#{inspect(errors)}")
    end
  end

  defp log(%Context{halt: true} = ctx) do
    Logger.info("#{__MODULE__}.ingest halted process. reason=#{ctx.reason}")
    ctx
  end

  defp log(ctx) do
    ctx
  end
end
