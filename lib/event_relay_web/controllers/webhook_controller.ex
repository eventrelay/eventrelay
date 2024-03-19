defmodule ERWeb.WebhookController do
  use ERWeb, :controller

  require Logger
  alias Flamel.Context
  alias Webhoox.Authentication.StandardWebhook
  alias ER.Transformers.Transformer

  action_fallback(ERWeb.FallbackController)

  def ingest(conn, params) do
    %Context{}
    |> check_rate_limit()
    |> assign_event(conn, params)
    |> produce_event()
    |> log()
    |> send_response(conn)
  end

  defp send_response(%Context{halt?: true, reason: "Rate limit" <> reason} = _ctx, conn) do
    conn
    |> put_status(:too_many_requests)
    |> text("Rate limit" <> reason)
  end

  defp send_response(%Context{halt?: true} = _ctx, conn) do
    conn
    |> put_status(:ok)
    |> text("OK")
  end

  defp send_response(%Context{halt?: false}, conn) do
    conn
    |> put_status(:ok)
    |> text("OK")
  end

  defp assign_event(%Context{halt?: true} = ctx, _conn, _params) do
    ctx
  end

  defp assign_event(context, conn, params) do
    source = conn.assigns[:source]
    # TODO improve this with a full implementation of Webhoox
    {data, verified, event_name} =
      if source.type == :standard_webhook do
        body_params = conn.body_params
        signing_secret = source.config["signing_secret"]

        if StandardWebhook.verify(conn, body_params, signing_secret) do
          # verified
          {params["data"], true, params["type"]}
        else
          # not verified
          {params["data"], false, params["type"]}
        end
      else
        {Map.drop(params, ["source_id"]), false, source.event_name || "webhook.inbound"}
      end

    topic_name = source.topic_name

    attrs =
      %{
        name: event_name,
        source: source.source,
        data: data,
        verified: verified,
        topic_name: topic_name
      }
      |> Transformer.transform(source)
      |> Map.put_new(:verified, verified)

    Context.assign(context, :event, attrs)
  end

  defp check_rate_limit(ctx) do
    case ERWeb.RateLimiter.check_rate("publish_events", []) do
      {:allow, _count} ->
        ctx

      {:deny, method, time_frame, max_req} ->
        Context.halt!(
          ctx,
          "Rate limit exceeded for #{method} at #{max_req} requests per #{time_frame / 1000} second(s)"
        )
    end
  end

  defp produce_event(%Context{halt?: true} = ctx) do
    ctx
  end

  defp produce_event(ctx) do
    event = ctx.assigns[:event]
    ER.Events.Batcher.Server.add(event[:topic_name], [event])
    ctx
  end

  defp log(%Context{halt?: true} = ctx) do
    Logger.info("#{__MODULE__}.ingest halted process. reason=#{ctx.reason}")
    ctx
  end

  defp log(ctx) do
    ctx
  end
end
