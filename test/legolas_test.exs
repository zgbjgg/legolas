defmodule LegolasTest do
  use ExUnit.Case
  doctest Legolas

  test "greets the world" do
    assert Legolas.hello() == :world
  end
end
