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

      def via_tuple(id) do
        Logger.debug("#{__MODULE__}.via_tuple(#{inspect(id)})")
        {:via, Registry, {ER.Registry, id}}
      end
    end
  end
end
