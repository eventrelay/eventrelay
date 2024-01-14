defmodule ER.Destinations.Pipeline.Webhook.Retries do
  def next(destination, _delivery, attempts, now \\ DateTime.utc_now()) do
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

    if Flamel.Context.halted?(strategy) do
      {strategy, nil}
    else
      {strategy, DateTime.add(now, interval, :millisecond)}
    end
  end
end
