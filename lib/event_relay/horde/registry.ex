defmodule ER.Horde.Registry do
  @moduledoc """
  Manages the distributed registry
  """
  use Horde.Registry
  require Logger

  def start_link(init_arg, options \\ []) do
    options =
      options
      |> Keyword.put(:name, Keyword.get(init_arg, :name))
      |> Keyword.put(:strategy, Keyword.get(init_arg, :strategy))
      |> Keyword.put(:keys, Keyword.get(init_arg, :keys))

    Horde.Registry.start_link(__MODULE__, init_arg, options)
  end

  def init(init_arg) do
    [members: get_members()]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  defp get_members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {ER.HordeRegistry, node} end)
  end
end
