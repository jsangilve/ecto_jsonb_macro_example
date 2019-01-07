defmodule JsonbMacroExampleTest do
  use ExUnit.Case
  doctest JsonbMacroExample

  test "greets the world" do
    assert JsonbMacroExample.hello() == :world
  end
end
