defmodule ER.Horde.Supervisor do
  @moduledoc """
  Distributed Supervisor
  """
  use Horde.DynamicSupervisor
  require Logger

  def start_link(init_arg, options \\ []) do
    options =
      options
      |> Keyword.put(:name, Keyword.get(init_arg, :name))
      |> Keyword.put(:strategy, Keyword.get(init_arg, :strategy))
      |> Keyword.put(:shutdown, Keyword.get(init_arg, :shutdown))

    Horde.DynamicSupervisor.start_link(__MODULE__, init_arg, options)
  end

  def init(init_arg) do
    [strategy: :one_for_one, members: get_members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  defp get_members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {ER.HordeSupervisor, node} end)
  end
end
