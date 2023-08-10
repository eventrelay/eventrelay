defmodule ER.Lua do
  def eval(script, globals) do
    Enum.reduce(globals, Lua.State.new(), fn {key, val}, state ->
      Lua.set_global(state, key, val)
    end)
    |> Lua.eval!(script)
    |> Enum.at(0)
  end
end
