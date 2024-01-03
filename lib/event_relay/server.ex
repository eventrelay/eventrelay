defmodule ER.Server do
  @moduledoc """
  Functions for Genservers
  """

  defmacro __using__(_opts) do
    quote do
      require Logger

      @spec factory(binary()) :: any()
      def factory(id, args \\ %{}) do
        name = name(id)

        Logger.debug(
          "#{__MODULE__}.factory(#{inspect(id)}, #{inspect(args)}) with module=#{inspect(__MODULE__)} and name=#{inspect(name)}"
        )

        initial_state = Map.merge(args, %{"id" => id})

        result =
          DynamicSupervisor.start_child(
            ER.DynamicSupervisor,
            {__MODULE__, [name: name, initial_state: initial_state]}
          )

        Logger.debug(
          "#{__MODULE__}.factory(#{inspect(id)}, #{inspect(args)}) with result=#{inspect(result)}"
        )

        result
      end

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
        Process.flag(:trap_exit, true)
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

      def terminate(reason, state) do
        Logger.debug(
          "#{__MODULE__} terminating with reason=#{inspect(reason)} with state=#{inspect(state)}"
        )

        handle_terminate(reason, state)
      end

      def via(id) do
        id
        |> name()
        |> via_tuple()
      end

      def via_tuple(id) do
        Logger.debug("#{__MODULE__}.via_tuple(#{inspect(id)})")
        {:via, Registry, {ER.Registry, id}}
      end
    end
  end
end
