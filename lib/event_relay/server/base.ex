defmodule ER.Server.Base do
  @moduledoc """
  Functions for Genservers
  """

  defmacro __using__(_opts) do
    quote do
      require Logger

      def child_spec(opts) do
        name = Keyword.get(opts, :name, __MODULE__)
        initial_state = Keyword.get(opts, :initial_state, %{})

        %{
          id: "#{__MODULE__}_#{name}",
          start: {__MODULE__, :start_link, [name, initial_state]},
          shutdown: 5_000
        }
      end

      def init(args) do
        {:ok, args, {:continue, :load_state}}
      end

      def start_link(name, initial_state) do
        case GenServer.start_link(__MODULE__, initial_state, name: via_tuple(name)) do
          {:ok, pid} ->
            Logger.info(
              "#{__MODULE__}.start_link here: starting #{inspect(via_tuple(name))} on node=#{inspect(Node.self())}"
            )

            {:ok, pid}

          {:error, {:already_started, pid}} ->
            Logger.info(
              "#{__MODULE__}.start_link: already started at #{inspect(pid)}, returning :ignore on node=#{inspect(Node.self())}"
            )

            :ignore

          :ignore ->
            Logger.info("#{__MODULE__}.start_link :ignore on node=#{inspect(Node.self())}")
            :ignore
        end
      end

      def stop(id) do
        GenServer.cast(via(id), :stop)
      end

      def handle_cast(:stop, state) do
        Logger.debug(
          "#{__MODULE__}.handle_cast(:stop, #{inspect(state)}) on node=#{inspect(Node.self())}"
        )

        {:stop, :shutdown, state}
      end

      def via(id) do
        id
        |> name()
        |> via_tuple()
      end
    end
  end
end
