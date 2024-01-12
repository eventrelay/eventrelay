defmodule ER.Destinations.Pipeline.Base do
  defmacro __using__(_opts) do
    quote do
      require Logger
      alias Broadway.Message
      alias ER.Destinations.Destination
      alias ER.Destinations.Pipeline.BroadwayConfig

      def child_spec(arg) do
        destination = arg[:destination]

        child_spec = %{
          id: "#{__MODULE__}:base:#{name(destination.id)}",
          start: {__MODULE__, :start_link, [arg]},
          shutdown: :infinity
        }

        Logger.debug("#{__MODULE__}.child_spec with child_spec=#{inspect(child_spec)}")

        child_spec
      end

      def get_broadway_config(%Destination{config: config} = destination) do
        # TOOD Maybe add some jitter to the pull_interval. To avoid all pipelines
        # making calls to the db very close to each other.
        config
        |> Map.get("pipeline", %{})
        |> Map.put(:destination, destination)
        |> Map.put(:name, via(destination.id))
        |> Flamel.Map.atomize_keys()
        |> BroadwayConfig.new()
      end

      def get_broadway_config(_) do
        BroadwayConfig.new()
      end

      def handle_event?(destination, event) do
        Destination.matches?(destination, event)
      end

      def via(id) do
        id
        |> name()
        |> via_tuple()
      end

      def via_tuple(name) do
        {:via, Registry, {ER.Registry, name}}
      end
    end
  end
end
