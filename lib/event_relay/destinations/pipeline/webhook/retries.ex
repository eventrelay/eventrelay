defmodule ER.Destinations.Pipeline.Webhook.Retries do
  def next(destination, response, attempts, now \\ Flamel.Moment.CurrentTime.utc_now()) do
    # we a substracting 1 because the strategy will increment
    # the attempt count 
    attempt = Enum.count(attempts) - 1

    strategy =
      destination.config
      |> Map.get("retries", %{})
      |> Map.take(["max_interval", "max_attempts", "base", "multiplier"])
      |> Map.put_new("max_attempts", 10)
      |> Map.put_new("max_interval", 256_000)
      |> Map.put("attempt", attempt)
      |> Flamel.Map.atomize_keys()
      |> Flamel.Retryable.exponential()

    strategy =
      Flamel.Retryable.Strategy.calc(strategy)

    # we need to turn this into minutes
    interval = (strategy.interval * 60) |> Flamel.to_integer()

    available_at =
      if Flamel.Context.halted?(strategy) do
        nil
      else
        DateTime.add(now, interval, :millisecond)
      end

    # alter based on http response
    # TODO: move this into Flamel HTTP strategy
    case {strategy, available_at, response} do
      # response is a 410 GONE so halt retries
      {strategy, _, {:error, %{status: 410}}} ->
        {Flamel.Context.halt!(strategy, "HTTP 410 GONE"), nil}

      {strategy, original_available_at, {:error, %{headers: %{"RETRY-AFTER" => retry_after}}}} ->
        available_at = parse_retry_after(retry_after, now, original_available_at)
        {strategy, available_at}

      # default case
      {strategy, available_at, _} ->
        {strategy, available_at}
    end
  end

  defp parse_retry_after(nil, _now, original_available_at), do: original_available_at
  defp parse_retry_after("", _now, original_available_at), do: original_available_at

  defp parse_retry_after(retry_after, now, _original_available_at) when is_integer(retry_after) do
    retry_after = Flamel.to_integer(retry_after)
    DateTime.add(now, retry_after, :second)
  end

  defp parse_retry_after(retry_after, now, original_available_at) do
    case Calendar.DateTime.Parse.rfc2822_utc(retry_after) do
      {:ok, datetime} ->
        datetime

      _ ->
        retry_after
        |> Flamel.to_integer()
        |> parse_retry_after(now, original_available_at)
    end
  end
end
