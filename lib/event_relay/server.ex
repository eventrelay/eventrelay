defmodule ER.Server do
  @moduledoc """
  Functions for Genservers
  """

  defmacro __using__(_opts) do
    quote do
      @spec factory(binary()) :: any()
      def factory(id, args \\ %{}) do
        initial_state = Map.merge(args, %{"id" => id})

        Horde.DynamicSupervisor.start_child(
          ER.Horde.Supervisor,
          {__MODULE__, [name: name(id), initial_state: initial_state]}
        )
      end

      def child_spec(opts) do
        name = Keyword.get(opts, :name, __MODULE__)
        initial_state = Keyword.get(opts, :initial_state, %{})

        %{
          id: "#{__MODULE__}_#{name}",
          start: {__MODULE__, :start_link, [name, initial_state]},
          shutdown: 60_000,
          restart: :transient
        }
      end

      def init(args) do
        Process.flag(:trap_exit, true)
        {:ok, args, {:continue, :load_state}}
      end

      def start_link(name, initial_state) do
        case GenServer.start_link(__MODULE__, initial_state, name: via_tuple(name)) do
          {:ok, pid} ->
            Logger.debug(
              "#{__MODULE__}.start_link here: starting #{via_tuple(name)} on node=#{inspect(Node.self())}"
            )

            {:ok, pid}

          {:error, {:already_started, pid}} ->
            Logger.debug(
              "#{__MODULE__}.start_link: already started at #{inspect(pid)}, returning :ignore on node=#{inspect(Node.self())}"
            )

            :ignore

          :ignore ->
            Logger.debug("#{__MODULE__}.start_link :ignore on node=#{inspect(Node.self())}")
        end
      end

      @spec tick_interval() :: integer()
      def tick_interval do
        String.to_integer(System.get_env("ER_SUBSCRIPTION_SERVER_TICK_INTERVAL") || "5000")
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

      def terminate(reason, state) do
        Logger.debug(
          "#{__MODULE__} terminating with reason=#{inspect(reason)} with state=#{inspect(state)}"
        )

        handle_terminate(reason, state)
      end

      def schedule_next_tick() do
        Process.send_after(self(), :tick, tick_interval())
      end

      def via(id) do
        id
        |> name()
        |> via_tuple()
      end

      def via_tuple(id) do
        {:via, Horde.Registry, {ER.Horde.Registry, id}}
      end
    end
  end
end
