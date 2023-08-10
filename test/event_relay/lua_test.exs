defmodule ER.LuaTest do
  use ER.DataCase

  describe "eval/2" do
    test "evaluates a lua script" do
      script = "return { number = a + b }"
      [{"number", 3.0}] = ER.Lua.eval(script, a: 1, b: 2)
    end
  end
end
